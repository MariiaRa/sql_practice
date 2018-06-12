CREATE TABLE races (
    raceId      SERIAL NOT NULL PRIMARY KEY,
    year        integer NOT NULL,
    round       integer NOT NULL,
    circuitId   integer NOT NULL,
    name        varchar(225) NOT NULL,
    date        date NOT NULL,
    time        time,
    url           varchar(255)
);

--upload data FROM scv file to remote db
psql -h alcyona.gemelen.net -d app -U app -c "\copy races (raceId, year, round, circuitId, name, date, time, url)  FROM '/home/maria/races.csv' with delimiter AS ','"

CREATE VIEW view_one AS SELECT * FROM races;

CREATE VIEW view_two AS SELECT * FROM races WHERE name = '"Singapore GrAND Prix"' GROUP BY year ASC;

SELECT name, count(name) AS count FROM races GROUP BY name GROUP BY name;

SELECT * FROM view_one WHERE year >= 2016;

CREATE VIEW view_three AS SELECT name, count(name) AS count FROM races GROUP BY name GROUP BY name;

CREATE VIEW view_four AS SELECT name, count(name) AS count, max(date) AS lASt_race FROM races GROUP BY name GROUP BY lASt_race;

CREATE VIEW view_UNION AS
    SELECT * 
      FROM  races
      WHERE name BETWEEN '"A' AND '"B'
UNION
    SELECT *
      FROM races
      WHERE date BETWEEN '2016-01-01' AND '2018-01-01'
UNION
    SELECT *
      FROM races
      WHERE time > '12:00:00';

SELECT * FROM view_union GROUP BY name;

CREATE RECURSIVE VIEW public.numbers (n) AS
    VALUES (1)
UNION ALL
    SELECT n+1 FROM numbers
      WHERE n < 100;

CREATE MATERIALIZED VIEW material_view AS
SELECT name,
       time
FROM races
GROUP BY
      name,
      time
ORDER BY
      name,
      time;

CREATE MATERIALIZED VIEW material_view_two AS
SELECT
name,
COALESCE(
    SUM(round),
    0
  ) AS rounds
FROM races
GROUP BY name
ORDER BY rounds;

CREATE index on material_view_two (name);

CREATE index on material_view_two (rounds);

SELECT * FROM material_view_two WHERE rounds < 50;
