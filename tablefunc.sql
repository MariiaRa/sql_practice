-- table manipulations

psql -h alcyona.gemelen.net -U postgres app -c "CREATE EXTENSION IF NOT EXISTS tablefunc" 

CREATE TABLE evaluations (student varchar(50), subject varchar(50), result decimal(3,1), evaluation_date date);

INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Dave', 'Biology', 7.0, '2018-05-28');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Kelly', 'Biology', 9.1, '2018-05-28');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Joshua', 'Biology', 8.8, '2018-05-29');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Dave', 'Math', 9.0, '2018-05-21');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Kelly', 'Math', 7.7, '2018-05-21');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Joshua', 'Math', 8.0, '2018-05-22');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Dave', 'Chemistry', 8.4, '2018-05-17');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Kelly', 'Chemistry', 9.0, '2018-05-17');
INSERT INTO evaluations (student, subject, result, evaluation_date) VALUES ('Joshua', 'Chemistry', 8.9, '2018-05-18');

SELECT * 
FROM crosstab( 'SELECT student, subject, result FROM evaluations ORDER BY 1,2') 
     AS final_result(Student varchar(50), Biology numeric(3,1), Math numeric(3,1), Chemistry numeric(3,1));

CREATE materialized VIEW drivers_races AS
SELECT concat(drivers.forename, ' ', drivers.surname) AS driver,
       races.name,
       results.position
FROM drivers
INNER JOIN results ON drivers.driverId = results.driverId
INNER JOIN races ON results.raceId = races.raceId
WHERE races.year = 2000
  AND results.position > 0
ORDER BY races.name;

-- crosstab(text)

SELECT *
FROM crosstab ('SELECT driver, name, position FROM drivers_races ORDER BY 1,2') 
AS final_result(driver text, "Australian Grand Prix" INTEGER, "Austrian Grand Prix" INTEGER, "Belgian Grand Prix" INTEGER, "Brazilian Grand Prix" INTEGER, "British Grand Prix" INTEGER, "Canadian Grand Prix" INTEGER, "European Grand Prix" INTEGER, "German Grand Prix" INTEGER);

-- crosstab(text, text)

SELECT *
FROM crosstab ($$ SELECT driver, name, position FROM drivers_races ORDER BY 1 $$, $$ SELECT DISTINCT name FROM drivers_races WHERE name LIKE '"A%' ORDER BY 1; $$) 
AS result (driver text, "Australian Grand Prix" INTEGER, "Austrian Grand Prix" INTEGER);


SELECT *
FROM crosstab ($$ SELECT driver, name, position FROM drivers_races ORDER BY 1 $$, $$ SELECT DISTINCT name FROM drivers_races WHERE name LIKE '"B%' ORDER BY 1; $$) 
AS result (driver text, race1 INTEGER, race2 INTEGER, race3 INTEGER);

CREATE TABLE sales(year int, month int, qty int);
INSERT INTO sales VALUES(2016, 1, 1000);
INSERT INTO sales VALUES(2016, 2, 1500);
INSERT INTO sales VALUES(2016, 6, 1300);
INSERT INTO sales VALUES(2016, 7, 500);
INSERT INTO sales VALUES(2016, 11, 1500);
INSERT INTO sales VALUES(2016, 12, 2000);
INSERT INTO sales VALUES(2018, 1, 1000);
INSERT INTO sales VALUES(2018, 9, 15000);
INSERT INTO sales VALUES(2019, 1, 11000);


SELECT *
FROM crosstab( 'SELECT year, month, qty FROM sales ORDER BY 1', 'SELECT m FROM generate_series(1,12) m') AS 
( year int, 
  "January" int, 
  "February" int, 
  "Machr" int, 
  "April" int, 
  "May" int, 
  "June" int, 
  "July" int, 
  "August" int, 
  "September" int, 
  "October" int, 
  "November" int, 
  "December" int);


