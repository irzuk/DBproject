
-- #5 crud quires
-- 1) tasks
-- add new task
INSERT INTO tasks(project_id, name, status_id, creation_date)
VALUES (2, 'Prepare for the interns', 1, '2022-12-05 10:00:00.679985+02');
-- change a project for all tasks of certain project
UPDATE tasks
SET project_id=5
WHERE project_id = 4;
-- remove old tasks
DELETE
FROM tasks
WHERE creation_date < '2007-12-05';
-- get all tasks that are note Done yet.
SELECT *
FROM tasks
WHERE status_id != 1;

-- 2) teams
-- add new team
INSERT INTO teams(name)
VALUES ('Sales');
-- rename old one
UPDATE teams
SET name = name || ' Internal'
WHERE NOT (name LIKE 'Chrome%');
-- remove all data about team #4
DELETE
FROM team_X_user
WHERE team_id = 4;
DELETE
FROM team_x_project
WHERE team_id = 4;
DELETE
FROM teams
WHERE team_id = 4;
-- get number of projects for each team
SELECT name, count(*)
FROM teams
         inner join team_X_project tXp on teams.team_id = tXp.team_id
GROUP BY name;

-- #7
DROP SCHEMA IF EXISTS db_project_views CASCADE;
CREATE SCHEMA db_project_views;
--SET SEARCH_PATH = db_project_views;

DROP VIEW IF EXISTS db_project_views.users;
CREATE VIEW db_project_views.users as
(
SELECT db_project.users.user_id,
       db_project.users.user_name,
       db_project.users.role_id,
       overlay(db_project.users.password placing '****' from 2)
FROM db_project.users
    );

DROP VIEW IF EXISTS db_project_views.statuses;
CREATE VIEW db_project_views.statuses as
(
SELECT db_project.statuses.name
FROM db_project.statuses
    );

DROP VIEW IF EXISTS db_project_views.roles;
CREATE VIEW db_project_views.roles as
(
SELECT db_project.roles.name
FROM db_project.roles
    );

DROP VIEW IF EXISTS db_project_views.teams;
CREATE VIEW db_project_views.teams as
(
SELECT db_project.teams.name
FROM db_project.teams
    );

DROP VIEW IF EXISTS db_project_views.projects;
CREATE VIEW db_project_views.projects as
(
SELECT db_project.projects.name,
       db_project.projects.description

FROM db_project.projects
    );

DROP VIEW IF EXISTS db_project_views.tasks;
CREATE VIEW db_project_views.tasks as
(
SELECT db_project.tasks.name,
       db_project.tasks.creation_date

FROM db_project.tasks
    );

DROP VIEW IF EXISTS db_project_views.teams_X_projects;
CREATE VIEW db_project_views.teams_X_projects as
(
SELECT t.name       as team,
       t.team_id    as team_id,
       p.name       as project,
       p.project_id as project_id
FROM (db_project.teams t inner join team_x_project txp on t.team_id = txp.team_id)
         inner join projects p on txp.project_id = p.project_id
    );

-- #6

--1 get for each username the project they are working with
SELECT DISTINCT project_id,
                uname as emploee_name
FROM (SELECT u.user_name as uname, team_id
      FROM users u
               inner join team_X_user txu on u.user_id = txu.user_id) as tt
         inner join team_x_project t
                    on tt.team_id = t.team_id
ORDER BY uname;

--2 get number of tasks of each status for user 4 that are not Done yet
SELECT name as status,
       cnt  as number_not_Done_tasks
FROM (SELECT status_id,
             count(*) as cnt
      FROM (SELECT DISTINCT project_id
            FROM (SELECT u.user_name as uname, team_id
                  FROM users u
                           inner join team_X_user txu on u.user_id = txu.user_id
                  WHERE u.user_id = 4) as tt
                     inner join team_x_project t
                                on tt.team_id = t.team_id) as ss
               inner join tasks t on ss.project_id = t.project_id
      GROUP BY status_id
      HAVING status_id != 1) as i
         inner join statuses on i.status_id = statuses.status_id;

--3 get how much interns we have in each team
SELECT team_id as team, COALESCE(COUNT(rr.user_id), 0) as num_of_interns
FROM team_X_user t
         left join (SELECT *
                    FROM users
                             inner join roles r on users.role_id = r.role_id
                    WHERE r.role_id = 5) as rr on rr.user_id = t.user_id
GROUP BY team;

--4 for each team find out the longest duration for task with status In progress
SELECT t.team,
       max(COALESCE(s.valid_until, now()::date) - tasks.creation_date) as longest_task_in_progress
FROM (db_project_views.teams_X_projects t inner join tasks on t.project_id = tasks.project_id)
         left join status_history s on tasks.task_id = s.task_id
WHERE s.status_id is null
   or s.status_id = 2
GROUP BY t.team
ORDER BY longest_task_in_progress DESC;


--5 for each task write which status and how long does it have
SELECT task_id,
       u.name                                                                    as task_name,
       s.name                                                                    as status,
       time - lag(time, 1, start_date) over (partition by task_id order by time) as duration_of_status
FROM (SELECT task_id,
             name,
             status_id,
             creation_date as start_date,
             now()::date   as time
      FROM tasks t
      union all
      SELECT tasks.task_id,
             name,
             sh.status_id,
             lag(valid_until, 1, creation_date) over (partition by tasks.task_id order by sh.valid_until) as start_date,
             valid_until                                                                                  as time
      FROM tasks
               inner join status_history sh on tasks.task_id = sh.task_id) as u
         inner join statuses s on u.status_id = s.status_id;

-- 8 3 views

-- 1)  for each project show how much tasks did we have for each day till now

CREATE RECURSIVE VIEW days(n) as
(
SELECT min(db_project.tasks.creation_date) as d
FROM db_project.tasks
UNION ALL
SELECT n + 1 as dt
FROM days
where n < (select max(db_project.tasks.creation_date) from db_project.tasks));

DROP VIEW IF EXISTS num_of_tasks;
CREATE VIEW num_of_tasks as
(
SELECT DISTINCT days.n, projects.name, count(projects.name) over (partition by projects.name order by days.n )
FROM days
         left join (projects
    inner join tasks t on projects.project_id = t.project_id) on days.n = t.creation_date
ORDER BY days.n);

SELECT *
FROM num_of_tasks;
-- 2) last activity for each user
DROP VIEW IF EXISTS last_activity;
CREATE VIEW last_activity as
(
SELECT username, tasks.name as task_name, label, time
FROM (SELECT max(a.time) over (partition by user_name) as t,
             a.time                                    as time,
             users.user_name                           as username,
             a.label                                   as label,
             a.task_id                                 as task_id
      FROM users
               left join actions a on users.user_id = a.user_id) as subq
         left join tasks on subq.task_id = tasks.task_id
WHERE date_trunc('day', t) = date_trunc('day', time)
   or label IS NULL
    );

SELECT *
FROM last_activity;

-- 3) for each role count how many action they do
DROP VIEW IF EXISTS types_per_role;
CREATE VIEW types_per_role as
(
SELECT roles.name as role,
       label      as lable,
       count(*)
FROM (roles left join users u on roles.role_id = u.role_id)
         left join actions a on u.user_id = a.user_id
GROUP BY role, lable);

SELECT *
FROM types_per_role;

-- 9 2 triggers

-- 1) update for version table of statuses:
-- once we change status for a task we have trigger that add old status to history status table

-- 2)

-- 10 2 procedures

-- 1) create action of changed status:
-- once we change status for a task we have trigger that add old status to history status table + provide user id

-- 2) create action:
-- once we insert/update status we create that as action in the table + provide user id
