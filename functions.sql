CREATE FUNCTION add(x integer, y integer) RETURNS integer AS $$
    SELECT x + y;
$$ LANGUAGE plpgsql;

SELECT add(6, 666) AS answer;

-- SQL Functions on Composite Types

CREATE TABLE emp (
    name        text,
    salary      numeric,
    age         integer
 );

INSERT INTO emp VALUES ('Bill', 4200, 45);

CREATE FUNCTION double_salary(emp) RETURNS numeric AS $$
    SELECT $1.salary * 2 AS salary;
$$ LANGUAGE SQL;

SELECT name, double_salary(emp.*) AS dream
    FROM emp
    WHERE emp.name = 'Bill';

CREATE FUNCTION new_emp() RETURNS emp AS $$
    SELECT text 'None' AS name,
        1000.0 AS salary,
        25 AS age;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION new_emp() RETURNS emp AS $$
    SELECT ROW('None', 1000.0, 25)::emp;
$$ LANGUAGE SQL;

select * from new_emp();
SELECT new_emp();
SELECT (new_emp()).salary;
SELECT age(new_emp());

CREATE FUNCTION getname(emp) RETURNS text AS $$
    SELECT $1.name;
$$ LANGUAGE SQL;

SELECT getname(new_emp());

--  SQL Functions with Output Parameters

CREATE FUNCTION add_out (IN x int, IN y int, OUT sum int)
AS $$
SELECT x + y;
$$
LANGUAGE SQL;

select * from add_out(666778, 12345678);


CREATE FUNCTION sum_and_product (x int, y int, OUT sum int, OUT product int)
AS $$
SELECT x + y, x * y;
$$
LANGUAGE SQL;

 SELECT * FROM sum_and_product(11111,1111);

CREATE TYPE sum_prod AS (sum int, product int);

CREATE OR REPLACE FUNCTION sum_and_product (int, int) RETURNS sum_prod
AS $$
SELECT $1 + $2, $1 * $2;
$$
LANGUAGE SQL;

-- SQL Functions with Variable Numbers of Arguments

CREATE FUNCTION mleast(VARIADIC arr numeric[]) RETURNS numeric AS $$
    SELECT min($1[i]) FROM generate_subscripts($1, 1) g(i);
$$ LANGUAGE SQL;


select * from generate_subscripts('{10, -1, 5, 4}'::int[], 1);

SELECT mleast(VARIADIC ARRAY[10, -1, 5, -4.4]);

SELECT mleast(VARIADIC arr := ARRAY[10, 1, 5, 4.4]);


