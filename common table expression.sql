-- CTE

CREATE TABLE drivers (driverId INTEGER NOT NULL PRIMARY KEY,
                      driverRef varchar(255) NOT NULL, 
                      number INTEGER DEFAULT NULL,
                      code varchar(3) DEFAULT NULL,
                      forename varchar(255) NOT NULL,
                      surname varchar(255) NOT NULL,
                      dob DATE DEFAULT NULL,
                      nationality varchar(255) DEFAULT NULL,
                      url varchar(255) NOT NULL);

psql -h alcyona.gemelen.net -d app -U app -c "\copy drivers (driverId, driverRef, number, code,forename, surname, dob, nationality, url) 
FROM '/home/maria/driver.csv' WITH delimiter AS ','"
CREATE TABLE results (resultId INTEGER NOT NULL PRIMARY KEY,
                      raceId INTEGER NOT NULL,
                      driverId INTEGER NOT NULL,
                      constructorId INTEGER NOT NULL, number INTEGER DEFAULT NULL,
                      grid INTEGER NOT NULL,
                      POSITION INTEGER DEFAULT NULL,
                      positionText varchar(255) NOT NULL,
                      positionOrder INTEGER NOT NULL,                 
                      points float8 NOT NULL,                 
                      laps INTEGER NOT NULL,
                      time varchar(255) DEFAULT NULL,
                      milliseconds INTEGER DEFAULT NULL,
                      fastestLap INTEGER DEFAULT NULL,
                      rank INTEGER, 
                      fastestLapTime varchar(255) DEFAULT NULL,
                      fastestLapSpeed float8 DEFAULT NULL,
                      statusId INTEGER);

psql -h alcyona.gemelen.net -d app -U app -c "\copy results (resultId, raceId, driverId, constructorId,number, grid, position, positionText, positionOrder, points, laps,
time, milliseconds, fastestLap, rank, fastestLapTime, fastestLapSpeed, statusId) FROM '/home/maria/results.csv' WITH delimiter AS ','" 

WITH driver AS
  (SELECT concat(drivers.forename, ' ', drivers.surname) AS name,
          results.position AS POSITION,
          results.fastestLapTime AS best_time,
          results.fastestLapSpeed AS best_speed,
          races.name AS race_name,
          races.date AS race_date,
          races.year AS race_year
   FROM drivers
   INNER JOIN results ON drivers.driverId = results.driverId
   INNER JOIN races ON results.raceId = races.raceId)
SELECT *
FROM driver
WHERE name = 'Michael Schumacher'
ORDER BY race_year;

WITH driver AS
  (SELECT drivers.driverId,
          concat(drivers.forename, ' ', drivers.surname) AS name,
          array_agg(concat(results.position)) AS positions,
   FROM drivers
   INNER JOIN results ON drivers.driverId = results.driverId
   GROUP BY drivers.driverId)
SELECT *
FROM driver;

WITH driver AS
  (SELECT concat(drivers.forename, ' ', drivers.surname) AS name,
          results.position AS POSITION,
          results.fastestLapTime AS best_time,
          results.fastestLapSpeed AS best_speed,
          races.name AS race_name,
          races.date AS race_date,
          races.year AS race_year
   FROM drivers
   INNER JOIN results ON drivers.driverId = results.driverId
   INNER JOIN races ON results.raceId = races.raceId)
SELECT *
FROM driver
WHERE name = 'Michael Schumacher'
  AND race_name = '"German Grand Prix"'
ORDER BY POSITION;

-- multiple CTEs
WITH nationalities AS
  (SELECT drivers.nationality AS nations,
          count(races.name) AS races
   FROM drivers
   INNER JOIN results ON drivers.driverId = results.driverId
   INNER JOIN races ON results.raceId = races.raceId
   WHERE results.position = 1
   GROUP BY drivers.nationality
   ORDER BY races DESC),
     drivers_top AS
  (SELECT drivers.forename,
          drivers.surname,
          drivers.nationality AS nationality
   FROM drivers
   INNER JOIN results ON results.driverId = drivers.driverId
   WHERE results.position = 1
   GROUP BY drivers.forename,
            drivers.surname,
            drivers.nationality)
SELECT nationalities.nations,
       nationalities.races AS race_count,
       array_agg(concat('[', drivers_top.forename, ' ', drivers_top.surname, ']')) AS drivers
FROM nationalities
INNER JOIN drivers_top ON nationalities.nations = drivers_top.nationality
GROUP BY nationalities.nations,
         nationalities.races
ORDER BY race_count DESC;

--simple CTE
 WITH numbers AS
  ( SELECT generate_series(1, 15) AS number)
SELECT *
FROM numbers;

-- recursive CTE recursive essentially becomes a dynamically-built temporary table
 WITH RECURSIVE numbers (number) AS
  ( SELECT 1
   UNION SELECT number + 1
   FROM numbers
   WHERE number < 15 )
SELECT *
FROM numbers;

WITH RECURSIVE fz (number, value) AS
  (SELECT 0,
          FALSE
   UNION SELECT (number+1), (number+1)%3 = 0
   FROM fz
   WHERE number < 33 )
SELECT *
FROM fz;

WITH RECURSIVE fz (number, value) AS
  (SELECT 0,
          '0'
   UNION SELECT (number+1), CASE
                                WHEN (number+1)%15 = 0 THEN 'FizzBuzz'
                                WHEN (number+1)%5 = 0 THEN 'Buzz'
                                WHEN (number+1)%3 = 0 THEN 'Fizz'
                                ELSE (number+1)::text
                            END
   FROM fz
   WHERE number < 33 )
SELECT *
FROM fz
WHERE number >0;

-- select all drivers from race with id = 1
 WITH RECURSIVE drivers_per_race AS
  (SELECT raceId,
          driverId
   FROM results
   WHERE raceId = 1
   UNION SELECT x.raceId,
                x.driverId
   FROM results x
   INNER JOIN drivers_per_race s ON s.raceId = x.raceId)
SELECT *
FROM drivers_per_race;

) -- select all drivers from respective races
 WITH RECURSIVE drivers_per_race AS
  (SELECT raceId,
          driverId
   FROM results
   UNION SELECT x.raceId,
                x.driverId
   FROM results x
   INNER JOIN drivers_per_race s ON s.raceId = x.raceId)
SELECT drivers_per_race.raceId,
       array_agg(concat('[', drivers.forename, ' ', drivers.surname, ']')) AS driver,
       races.name,
       races.year
FROM drivers_per_race
INNER JOIN drivers ON drivers_per_race.driverId = drivers.driverId
INNER JOIN races ON drivers_per_race.raceId = races.raceId
WHERE races.name = '"Japanese Grand Prix"'
GROUP BY drivers_per_race.raceId,
         races.name,
         races.year
ORDER BY races.year ASC;
