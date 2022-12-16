-- 3 ddl scripts
CREATE SCHEMA db_project;
SET SEARCH_PATH = db_project;

-- Создание таблиц
DROP TABLE IF EXISTS teams CASCADE;
CREATE TABLE teams
(
    team_id serial PRIMARY KEY,
    name    VARCHAR(100) NOT NULL
);

DROP TABLE IF EXISTS statuses CASCADE;
CREATE TABLE statuses
(
    status_id serial PRIMARY KEY,
    name      VARCHAR(100) NOT NULL CHECK ( length(name) < 15)
);

DROP TABLE IF EXISTS roles CASCADE;
CREATE TABLE roles
(
    role_id serial PRIMARY KEY,
    name    VARCHAR(100) NOT NULL CHECK ( length(name) < 15)
);

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users
(
    user_id   serial PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL CHECK ( length(user_name) > 4),
    role_id   INTEGER,
    password  VARCHAR(15) CHECK ( length(password) > 5 and
                                  password ~* '^(?=.*[^a-zA-Z0-9])(?=.{5,}$)'),
    CONSTRAINT fk_role
        FOREIGN KEY (role_id)
            REFERENCES roles (role_id)
);

DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects
(
    project_id  serial PRIMARY KEY,
    name        VARCHAR(100) NOT NULL CHECK ( length(name) > 0),
    description VARCHAR(100) NOT NULL CHECK ( length(description) < 200)
);

DROP TABLE IF EXISTS tasks CASCADE;
CREATE TABLE tasks
(
    task_id       serial PRIMARY KEY,
    name          VARCHAR(50),
    project_id    INTEGER NOT NULL,
    status_id     INTEGER NOT NULL,
    creation_date DATE DEFAULT now(),
    CONSTRAINT fk_project
        FOREIGN KEY (project_id)
            REFERENCES projects (project_id),
    CONSTRAINT fk_status
        FOREIGN KEY (status_id)
            REFERENCES statuses (status_id)
);

DROP TABLE IF EXISTS actions CASCADE;
CREATE TABLE actions
(
    action_id serial PRIMARY KEY,
    user_id   INTEGER      NOT NULL,
    task_id   INTEGER      NOT NULL,
    time      DATE DEFAULT now(),
    label     VARCHAR(100) NOT NULL,
    object    JSON,
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
            REFERENCES users (user_id),
    CONSTRAINT fk_task
        FOREIGN KEY (task_id)
            REFERENCES tasks (task_id)
);

DROP TABLE IF EXISTS status_history CASCADE;
CREATE TABLE status_history
(
    task_id     INTEGER NOT NULL,
    status_id   INTEGER NOT NULL,
    valid_until DATE DEFAULT now()::date,
    CONSTRAINT fk_task
        FOREIGN KEY (task_id)
            REFERENCES tasks (task_id),
    CONSTRAINT fk_status
        FOREIGN KEY (status_id)
            REFERENCES statuses (status_id),
    PRIMARY KEY (task_id, status_id)
);

DROP TABLE IF EXISTS team_X_project CASCADE;
CREATE TABLE team_X_project
(
    team_id    INTEGER NOT NULL,
    project_id INTEGER NOT NULL,
    CONSTRAINT fk_team
        FOREIGN KEY (team_id)
            REFERENCES teams (team_id),
    CONSTRAINT fk_project
        FOREIGN KEY (project_id)
            REFERENCES projects (project_id),
    PRIMARY KEY (team_id, project_id)
);

DROP TABLE IF EXISTS project_X_status CASCADE;
CREATE TABLE project_X_status
(
    project_id INTEGER NOT NULL,
    status_id  INTEGER NOT NULL,
    CONSTRAINT fk_project
        FOREIGN KEY (project_id)
            REFERENCES projects (project_id),
    CONSTRAINT fk_status
        FOREIGN KEY (status_id)
            REFERENCES statuses (status_id),
    PRIMARY KEY (project_id, status_id)
);

DROP TABLE IF EXISTS team_X_user CASCADE;
CREATE TABLE team_X_user
(
    team_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    CONSTRAINT fk_team
        FOREIGN KEY (team_id)
            REFERENCES teams (team_id),
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
            REFERENCES users (user_id),
    PRIMARY KEY (team_id, user_id)
);

-- 4 fill in the tables

INSERT INTO teams(name)
VALUES ('Chrome OS');
INSERT INTO teams(name)
VALUES ('Security');
INSERT INTO teams(name)
VALUES ('Chrome');
INSERT INTO teams(name)
VALUES ('Android');
INSERT INTO teams(name)
VALUES ('Robots');

INSERT INTO statuses(name)
VALUES ('Done');
INSERT INTO statuses(name)
VALUES ('In progress');
INSERT INTO statuses(name)
VALUES ('In assembly');
INSERT INTO statuses(name)
VALUES ('UI approval');
INSERT INTO statuses(name)
VALUES ('Tech approval');

INSERT INTO roles(name)
VALUES ('Team lead');
INSERT INTO roles(name)
VALUES ('Manager');
INSERT INTO roles(name)
VALUES ('Designer');
INSERT INTO roles(name)
VALUES ('Developer');
INSERT INTO roles(name)
VALUES ('Intern');

INSERT INTO users(user_name, role_id, password)
VALUES ('krosh', 5, 'Morkov123!');
INSERT INTO users(user_name, role_id, password)
VALUES ('nusha', 5, 'P!nk007');
INSERT INTO users(user_name, role_id, password)
VALUES ('karkar', 1, 'En#g3neer');
INSERT INTO users(user_name, role_id, password)
VALUES ('sovunia', 2, 'V@ren1e');
INSERT INTO users(user_name, role_id, password)
VALUES ('ezjik', 3, 'Kr0sh!');
INSERT INTO users(user_name, role_id, password)
VALUES ('barash', 4, 'Str@dan1a');

INSERT INTO projects(name, description)
VALUES ('Robot', 'Create manipulator');
INSERT INTO projects(name, description)
VALUES ('Kiosk', 'Add button');
INSERT INTO projects(name, description)
VALUES ('Password manager', 'Make it secure');
INSERT INTO projects(name, description)
VALUES ('File loading', 'Make it secure');
INSERT INTO projects(name, description)
VALUES ('Update UI', 'New features');


INSERT INTO team_X_user(team_id, user_id)
VALUES (1, 4);
INSERT INTO team_X_user(team_id, user_id)
VALUES (2, 4);
INSERT INTO team_X_user(team_id, user_id)
VALUES (3, 4);
INSERT INTO team_X_user(team_id, user_id)
VALUES (4, 4);
INSERT INTO team_X_user(team_id, user_id)
VALUES (5, 4);
INSERT INTO team_X_user(team_id, user_id)
VALUES (1, 1);
INSERT INTO team_X_user(team_id, user_id)
VALUES (2, 2);
INSERT INTO team_X_user(team_id, user_id)
VALUES (4, 3);
INSERT INTO team_X_user(team_id, user_id)
VALUES (2, 5);
INSERT INTO team_X_user(team_id, user_id)
VALUES (5, 5);
INSERT INTO team_X_user(team_id, user_id)
VALUES (3, 6);

INSERT INTO team_X_project(team_id, project_id)
VALUES (5, 1);
INSERT INTO team_X_project(team_id, project_id)
VALUES (1, 2);
INSERT INTO team_X_project(team_id, project_id)
VALUES (1, 3);
INSERT INTO team_X_project(team_id, project_id)
VALUES (3, 3);
INSERT INTO team_X_project(team_id, project_id)
VALUES (2, 4);
INSERT INTO team_X_project(team_id, project_id)
VALUES (3, 4);
INSERT INTO team_X_project(team_id, project_id)
VALUES (1, 5);
INSERT INTO team_X_project(team_id, project_id)
VALUES (3, 5);
INSERT INTO team_X_project(team_id, project_id)
VALUES (4, 5);

INSERT INTO project_X_status(project_id, status_id)
VALUES (1, 1);
INSERT INTO project_X_status(project_id, status_id)
VALUES (1, 2);
INSERT INTO project_X_status(project_id, status_id)
VALUES (1, 3);
INSERT INTO project_X_status(project_id, status_id)
VALUES (1, 5);
INSERT INTO project_X_status(project_id, status_id)
VALUES (2, 1);
INSERT INTO project_X_status(project_id, status_id)
VALUES (2, 2);
INSERT INTO project_X_status(project_id, status_id)
VALUES (2, 4);
INSERT INTO project_X_status(project_id, status_id)
VALUES (3, 1);
INSERT INTO project_X_status(project_id, status_id)
VALUES (3, 2);
INSERT INTO project_X_status(project_id, status_id)
VALUES (4, 1);
INSERT INTO project_X_status(project_id, status_id)
VALUES (4, 2);
INSERT INTO project_X_status(project_id, status_id)
VALUES (5, 1);
INSERT INTO project_X_status(project_id, status_id)
VALUES (5, 2);
INSERT INTO project_X_status(project_id, status_id)
VALUES (5, 4);
INSERT INTO project_X_status(project_id, status_id)
VALUES (5, 5);

INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (1, 'Create design doc', 1, '2022-12-01 10:00:00.679985+02'); --Robot
INSERT INTO actions(user_id, task_id, time, label)
VALUES (4, 1, '2022-12-01 10:00:00.679985+02', 'CREATE');
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (1, 2, '2022-12-02 10:00:00.679985+02');
INSERT INTO actions(user_id, task_id, time, label)
VALUES (5, 1, '2022-12-02 10:00:00.679985+02', 'CHANGE STATUS');
INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (1, 'Make a platform', 3, '2022-12-01 10:00:00.679985+02'); --Robot
INSERT INTO actions(user_id, task_id, time, label)
VALUES (5, 2, '2022-12-01 10:00:00.679985+02', 'CREATE');
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (2, 2, '2022-12-02 10:00:00.679985+02');
INSERT INTO actions(user_id, task_id, time, label)
VALUES (4, 2, '2022-12-02 10:00:00.679985+02', 'CHANGE STATUS');
INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (1, 'Make a manipulator', 2, '2022-12-01 10:00:00.679985+02'); --Robot
INSERT INTO actions(user_id, task_id, time, label)
VALUES (4, 3, '2022-12-01 10:00:00.679985+02', 'CREATE');

INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (2, 'Add button', 4, '2022-12-02 10:00:00.679985+02'); --Kiosk
INSERT INTO actions(user_id, task_id, time, label)
VALUES (1, 4, '2022-12-02 10:00:00.679985+02', 'CREATE');
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (4, 2, '2022-12-05 10:00:00.679985+02');
INSERT INTO actions(user_id, task_id, time, label)
VALUES (5, 4, '2022-12-05 10:00:00.679985+02', 'CHANGE STATUS');

INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (3, 'Create design doc', 1, '2022-12-01 10:00:00.679985+02'); --Pass manager
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (5, 2, '2022-12-03 10:00:00.679985+02');
INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (3, 'Onboarding for intern', 3, '2022-12-05 10:00:00.679985+02'); --Pass manager
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (6, 2, '2022-12-06 10:00:00.679985+02');

INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (4, 'Discuss structure', 1, '2022-12-07 10:00:00.679985+02'); --File Loading
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (7, 2, '2022-12-08 10:00:00.679985+02');

INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (5, 'Discuss changes', 1, '2022-12-05 10:00:00.679985+02'); --Update UI
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (8, 2, '2022-12-08 10:00:00.679985+02');
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (8, 4, '2022-12-10 10:00:00.679985+02');
INSERT INTO status_history(task_id, status_id, valid_until)
VALUES (8, 5, '2022-12-11 10:00:00.679985+02');

