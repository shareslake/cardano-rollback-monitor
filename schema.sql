/*
 * This tool only has sense if you submit Tx thorugh the same node that db-sync is connected to
 */

CREATE SCHEMA rollback_monitor;

CREATE TABLE rollback_monitor.status (
   id bool PRIMARY KEY DEFAULT TRUE,
   in_progress bool DEFAULT FALSE,
);


-- Rollback starts when a block is deleted
CREATE OR REPLACE FUNCTION start_rollback() RETURNS trigger as $$
BEGIN
  UPDATE rollback_monitor.status SET in_progress=TRUE;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Prevent our schema to affect db-sync table updates if it fails
  RAISE WARNING 'There was an error setting rollback as started: %', sqlstate;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Rollback stops when a block is added
CREATE OR REPLACE FUNCTION stop_rollback() RETURNS trigger as $$
BEGIN
  IF ((SELECT in_progress FROM rollback_monitor.status) = TRUE) THEN
    UPDATE rollback_monitor.status SET in_progress=FALSE;
    PERFORM pg_notify('rollback_monitor', 'rollback finished');    
  END IF;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Prevent our schema to affect db-sync table updates if it fails
  RAISE WARNING 'There was an error setting rollback as finished: %', sqlstate;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Trigger to handle the start of a rollback */
CREATE OR REPLACE TRIGGER block_rollback BEFORE DELETE ON block
    FOR EACH ROW
    EXECUTE PROCEDURE start_rollback();

/* Trigger to handle the end of a rollback */
CREATE OR REPLACE TRIGGER new_block BEFORE INSERT ON block
    FOR EACH ROW
    EXECUTE PROCEDURE stop_rollback();
