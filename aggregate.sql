-- custom aggregate to find the sum of odd numbers
-- state transition function

CREATE OR REPLACE FUNCTION odds_sfunc(current_sum integer, NEXT integer) RETURNS integer IMMUTABLE LANGUAGE PLPGSQL AS $$
declare
 new_sum integer;
begin
   if next%2 = 0 THEN
    new_sum := current_sum;
  ELSE
    new_sum := current_sum + next;
  END if;
  return new_sum;
END;
$$;

-- create the aggregate by providing the state transition function, internal aggregate state type and initial condition

CREATE AGGREGATE odd_numbers_total (integer) 
( 
 sfunc = odds_sfunc,
 stype = integer, initcond = 0
);


SELECT odd_numbers_total(id)
FROM transactions;

-- custom aggregate to find the greatest running total

CREATE TABLE entries( 
  id serial PRIMARY KEY,
  amount float8 NOT NULL
);


SELECT setseed(0);


INSERT INTO entries(amount)
SELECT (2000 * random()) - 1000
FROM generate_series(1, 10);


SELECT id,
       amount,
       sum(amount) OVER (ORDER BY id ASC) AS running_total
FROM entries
ORDER BY id ASC;


SELECT MAX (running_total)
FROM
  (SELECT sum(amount) OVER (ORDER BY id ASC) AS running_total
   FROM entries) AS t;

-- or aggregate to calculate greatest running total
-- state transition function

CREATE FUNCTION grt_sfunc(agg_state POINT, el float8) RETURNS POINT IMMUTABLE LANGUAGE PLPGSQL AS $$
declare
  greatest_sum float8;
  current_sum float8;
begin
  current_sum := agg_state[0] + el;
  if agg_state[1] < current_sum THEN
    greatest_sum := current_sum;
  ELSE
    greatest_sum := agg_state[1];
  END if;

  return point(current_sum, greatest_sum);
END;
$$;

-- Because our aggregate's internal state is of type point and the output of our aggregate is float8, we need an aggregate final function that takes the final value of the aggregate's internal state and converts it to a float8.

CREATE FUNCTION grt_finalfunc(agg_state POINT) RETURNS float8 IMMUTABLE STRICT LANGUAGE PLPGSQL AS $$
begin
  return agg_state[1];
END;
$$;

-- create the aggregate by providing the state transition function, internal aggregate state type, the final function and initial condition.

CREATE AGGREGATE greatest_running_total (float8) 
( 
  sfunc = grt_sfunc,
  stype = POINT,
  finalfunc = grt_finalfunc 
  initcond = '(0.0 ,0.0 )'
);


SELECT greatest_running_total(amount ORDER BY id ASC)
FROM entries;

returns float8
immutable
strict
language plpgsql
AS $$
begin
  return agg_state[1];
END;
$$;

 -- create the aggregate by providing the state transition function, internal aggregate state type, the final function and initial condition. 

CREATE aggregate greatest_running_total (float8)
(
  sfunc = grt_sfunc,
  stype = point,
  finalfunc = grt_finalfunc
  initcond = '(0.0 ,0.0 )'
);

SELECT greatest_running_total(amount ORDER BY id ASC)
FROM entries;

