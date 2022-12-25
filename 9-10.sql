
-- 9 2 triggers

-- 1) update for version table of statuses:
-- once we change status for a task we have trigger that add old status to history status table
DROP FUNCTION IF EXISTS update_status_history CASCADE;
CREATE FUNCTION update_status_history() RETURNS trigger AS
$update_status_history$
BEGIN
    -- check if status applicable
    IF (SELECT project_id
        FROM db_project.project_X_status ps
                 inner join db_project.statuses s on ps.status_id = s.status_id
        WHERE ps.project_id = NEW.project_id
          and s.status_id = NEW.status_id) IS NULL THEN
        RAISE EXCEPTION 'Status is not allowed!';
    END IF;

    INSERT INTO db_project.status_history(task_id, status_id, valid_until) VALUES (OLD.task_id, OLD.status_id, now());
    RETURN NEW;
END ;
$update_status_history$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_status_history_tr ON db_project.tasks;
CREATE TRIGGER update_status_history_tr
    BEFORE UPDATE OR INSERT
    ON db_project.tasks
    FOR EACH ROW
    WHEN (OLD.status_id IS DISTINCT FROM NEW.status_id)
EXECUTE PROCEDURE update_status_history();

--test
--UPDATE db_project.tasks SET status_id=3 WHERE task_id = 5; exception
--UPDATE db_project.tasks SET status_id=1 WHERE task_id = 5; no changes
--UPDATE db_project.tasks SET status_id=2 WHERE task_id = 5; correct update

-- 2) check if user allowed to make action with task
DROP FUNCTION IF EXISTS check_action_allowance CASCADE;
CREATE FUNCTION check_action_allowance() RETURNS trigger AS
$check_action_allowance$
BEGIN
    IF (SELECT task_id
        FROM (SELECT DISTINCT project_id
              FROM (SELECT u.user_name as uname, team_id
                    FROM db_project.users u
                             inner join db_project.team_X_user txu on u.user_id = txu.user_id
                    WHERE u.user_id = NEW.user_id) as tt
                       inner join db_project.team_x_project t
                                  on tt.team_id = t.team_id) as ss
                 inner join db_project.tasks t on ss.project_id = t.project_id
        WHERE task_id = NEW.task_id) IS NULL THEN
        IF NEW.label = 'CREATE' THEN
            DELETE FROM db_project.tasks WHERE tasks.task_id = NEW.task_id;
        END IF;
        RAISE EXCEPTION 'Action is not allowed!';
    END IF;
    RETURN NEW;
END ;
$check_action_allowance$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_action_allowance_tr ON db_project.actions;
CREATE TRIGGER check_action_allowance_tr
    BEFORE INSERT
    ON db_project.actions
    FOR EACH ROW
EXECUTE PROCEDURE check_action_allowance();


-- 10 2 procedures

-- 1) create action of changed status:
-- once we change status for a task we have trigger that add old status to history status table + provide user id
DROP PROCEDURE IF EXISTS update_status;
CREATE PROCEDURE update_status(
    curr_user int, -- current user
    task int,
    status int
)
    language plpgsql
as
$$
begin
    -- update status with trigger that update history
    UPDATE db_project.tasks SET status_id=status WHERE task_id = task;
    -- insert action
    INSERT INTO db_project.actions(user_id, task_id, label) VALUES (curr_user, task, 'CHANGE_STATUS');
end;
$$;

CALL update_status(4, 5, 2);

-- 2) create action:
-- once we create new task we create action for user how did it
DROP PROCEDURE IF EXISTS create_task;
CREATE PROCEDURE create_task(
    curr_user int, -- current user
    project int,
    task_name text)
    language plpgsql
as
$$
DECLARE
    new_task_id int;
begin
    -- new_task_id := (SELECT nextval(pg_get_serial_sequence('db_project.tasks', 'task_id')) AS new_task_id);
    INSERT INTO db_project.tasks(project_id, name, status_id)
    VALUES (project, task_name, 1)
    RETURNING task_id INTO new_task_id;
    -- insert action(will be checked by trigger if it's allowed)
    INSERT INTO db_project.actions(user_id, task_id, label) VALUES (curr_user, new_task_id, 'CREATE');

end;
$$;