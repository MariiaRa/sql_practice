-- CTE

CREATE TABLE drivers (driverId INTEGER NOT NULL PRIMARY KEY, 
driverRef varchar(255) NOT NULL, 
number INTEGER default NULL, 
code varchar(3) default NULL,
forename varchar(255) NOT NULL, 
surname varchar(255) NOT NULL, 
dob DATE default NULL, 
nationality varchar(255) default NULL, 
url varchar(255) NOT NULL);

psql -h alcyona.gemelen.net -d app -U app -c "\copy drivers (driverId, driverRef, number, code,forename, surname, dob, nationality, url) 
FROM '/home/maria/driver.csv' WITH delimiter AS ','"

CREATE TABLE results (resultId INTEGER NOT NULL PRIMARY KEY, 
raceId INTEGER NOT NULL, 
driverId INTEGER NOT NULL, 
constructorId INTEGER NOT NULL,
number INTEGER default NULL, 
grid INTEGER NOT NULL, 
position INTEGER default NULL, 
positionText varchar(255) NOT NULL, 
positionOrder INTEGER NOT NULL, 
points float8 NOT NULL,
laps INTEGER NOT NULL, 
time varchar(255) default NULL, 
milliseconds INTEGER default NULL, 
fastestLap INTEGER default NULL, 
rank INTEGER, 
fastestLapTime varchar(255) default NULL, 
fastestLapSpeed float8 default NULL,
statusId INTEGER);

psql -h alcyona.gemelen.net -d app -U app -c "\copy results (resultId, raceId, driverId, constructorId,number, grid, position, positionText, positionOrder, points, laps,
time, milliseconds, fastestLap, rank, fastestLapTime, fastestLapSpeed, statusId) FROM '/home/maria/results.csv' WITH delimiter AS ','"

with
driver as
(select concat(drivers.forename, ' ' ,drivers.surname) as name,
results.position as position, 
results.fastestLapTime as best_time, 
results.fastestLapSpeed as best_speed,
races.name as race_name,
races.date as race_date,
races.year as race_year
from drivers
inner join results on drivers.driverId = results.driverId
inner join races on results.raceId = races.raceId)
select * from  driver where name = 'Michael Schumacher' order by race_year;

with
driver as
(select drivers.driverId,
concat(drivers.forename, ' ' ,drivers.surname) as name,
array_agg(concat(results.position)) as positions,
from drivers
inner join results on drivers.driverId = results.driverId
group by drivers.driverId)
select * from driver;

with
driver as
(select concat(drivers.forename, ' ' ,drivers.surname) as name,
results.position as position, 
results.fastestLapTime as best_time, 
results.fastestLapSpeed as best_speed,
races.name as race_name,
races.date as race_date,
races.year as race_year
from drivers
inner join results on drivers.driverId = results.driverId
inner join races on results.raceId = races.raceId)
select * from  driver where name = 'Michael Schumacher' and race_name = '"German Grand Prix"' order by position;

-- multiple CTEs
with
nationalities as 
(select drivers.nationality as nations,
count(races.name) as races
from drivers
inner join results on drivers.driverId = results.driverId
inner join races on results.raceId = races.raceId
where results.position = 1
group by drivers.nationality
order by races DESC
),
drivers_top as
(select drivers.forename, drivers.surname, drivers.nationality as nationality
from drivers
inner join results on results.driverId = drivers.driverId
where results.position = 1
group by drivers.forename, drivers.surname, drivers.nationality
)
select nationalities.nations,
nationalities.races as race_count,
array_agg(concat('[', drivers_top.forename, ' ' ,drivers_top.surname, ']')) as drivers
from nationalities
inner join drivers_top on nationalities.nations = drivers_top.nationality
group by nationalities.nations, nationalities.races
order by race_count DESC;

--simple CTE 

with numbers as (
  select generate_series(1,15) as number
)
select * from numbers;

-- recursive CTE recursive essentially becomes a dynamically-built temporary table

with recursive numbers (number) as (
  select 1
  union
  select number + 1
  from numbers
  where number < 15
)
select * from numbers;

with recursive fz (number, value) as 
(select 0, false
union
select (number+1),
(number+1)%3 = 0
from fz
where number < 33
)
select * from fz;

with recursive fz (number, value) as
(
select 0, '0'
union
select (number+1),
  case 
    when (number+1)%15 = 0 then 'FizzBuzz'
    when (number+1)%5 = 0 then 'Buzz'
    when (number+1)%3 = 0 then 'Fizz'
    else (number+1)::text
  end
from fz
where number < 33
)
select * from fz where number >0;

-- select all drivers from race with id = 1

with RECURSIVE drivers_per_race as 
(
select raceId, 
driverId
from results
where raceId = 1
union
select x.raceId, 
x.driverId
from results x
inner join drivers_per_race s on s.raceId = x.raceId)
select * from drivers_per_race;
)

-- select all drivers from respective races

with RECURSIVE drivers_per_race as 
(
select raceId, 
driverId
from results
union           
select x.raceId, 
x.driverId
from results x
inner join drivers_per_race s on s.raceId = x.raceId)
select drivers_per_race.raceId, 
array_agg(concat('[', drivers.forename, ' ', drivers.surname, ']')) as driver,
races.name,
races.year
from drivers_per_race
inner join drivers on drivers_per_race.driverId = drivers.driverId
inner join races on drivers_per_race.raceId = races.raceId
where races.name = '"Japanese Grand Prix"'
group by drivers_per_race.raceId, races.name, races.year
order by races.year asc;

