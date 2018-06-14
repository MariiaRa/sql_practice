-- custom aggregate to find the sum of odd numbers
-- state transition function

create or replace function odds_sfunc(current_sum integer, next integer)
returns integer
immutable
language plpgsql
as $$
declare
 new_sum integer;
begin
   if next%2 = 0 then
    new_sum := current_sum;
  else
    new_sum := current_sum + next;
  end if;
  return new_sum;
end;
$$;

-- create the aggregate by providing the state transition function, internal aggregate state type and initial condition

create aggregate odd_numbers_total (integer)
(
    sfunc = odds_sfunc,
    stype = integer,
initcond = 0
);

select odd_numbers_total(id) from transactions;


-- custom aggregate to find the greatest running total

create table entries(
  id serial primary key,
  amount float8 not null
);

select setseed(0);

insert into entries(amount)
select (2000 * random()) - 1000
from generate_series(1, 10);

select
  id,
  amount,
  sum(amount) over (order by id asc) as running_total
from entries
order by id asc;

select max (running_total) from ( select sum(amount) over (order by id asc) as running_total from entries) as t;

-- or aggregate to calculate greatest running total
-- state transition function

create function grt_sfunc(agg_state point, el float8)
returns point
immutable
language plpgsql
as $$
declare
  greatest_sum float8;
  current_sum float8;
begin
  current_sum := agg_state[0] + el;
  if agg_state[1] < current_sum then
    greatest_sum := current_sum;
  else
    greatest_sum := agg_state[1];
  end if;

  return point(current_sum, greatest_sum);
end;
$$;

-- Because our aggregate's internal state is of type point and the output of our aggregate is float8, we need an aggregate final function that takes the final value of the aggregate's internal state and converts it to a float8.

create function grt_finalfunc(agg_state point)
returns float8
immutable
strict
language plpgsql
as $$
begin
  return agg_state[1];
end;
$$;

 -- create the aggregate by providing the state transition function, internal aggregate state type, the final function and initial condition. 

create aggregate greatest_running_total (float8)
(
    sfunc = grt_sfunc,
    stype = point,
    finalfunc = grt_finalfunc
 initcond = '(0.0 ,0.0 )'
);

select greatest_running_total(amount order by id asc)
from entries;

