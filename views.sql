CREATE TABLE races ( raceId SERIAL NOT NULL PRIMARY KEY,
                     YEAR integer NOT NULL,
                     round integer NOT NULL,
                     circuitId integer NOT NULL,
                     name varchar(225) NOT NULL, 
                     date date NOT NULL,
                     TIME TIME,
                     url varchar(255));

--upload data FROM scv file to remote db
psql -h alcyona.gemelen.net -d app -U app -c "\copy races (raceId, year, round, circuitId, name, date, time, url)  FROM '/home/maria/races.csv' WITH delimiter AS ','"
CREATE VIEW view_one AS
SELECT *
FROM races;

CREATE VIEW view_two AS
SELECT *
FROM races
WHERE name = '"Singapore GrAND Prix"'
GROUP BY year ASC;


SELECT name,
       count(name) AS COUNT
FROM races
GROUP BY name
GROUP BY name;


SELECT *
FROM view_one
WHERE year >= 2016;


CREATE VIEW view_three AS
SELECT name,
       count(name) AS COUNT
FROM races
GROUP BY name
GROUP BY name;


CREATE VIEW view_four AS
SELECT name,
       count(name) AS COUNT,
       max(date) AS last_race
FROM races
GROUP BY name
GROUP BY last_race;


CREATE VIEW view_union AS
SELECT *
FROM races
WHERE name BETWEEN '"A' AND '"B'
UNION
SELECT *
FROM races
WHERE date BETWEEN '2016-01-01' AND '2018-01-01'
UNION
SELECT *
FROM races
WHERE TIME > '12:00:00';


SELECT *
FROM view_union
GROUP BY name;


CREATE RECURSIVE VIEW public.numbers (n) AS
VALUES (1)
UNION ALL
SELECT n+1
FROM numbers
WHERE n < 100;


CREATE MATERIALIZED VIEW material_view AS
SELECT name,
       time
FROM races
GROUP BY name,
         time
ORDER BY name,
         time;


CREATE MATERIALIZED VIEW material_view_two AS
SELECT name,
       COALESCE( SUM(round), 0 ) AS rounds
FROM races
GROUP BY name
ORDER BY rounds;


CREATE INDEX ON material_view_two (name);


CREATE INDEX ON material_view_two (rounds);


SELECT *
FROM material_view_two
WHERE rounds < 50;

--materialized view strategies

CREATE TABLE accounts( name varchar PRIMARY KEY);


INSERT INTO accounts(name)
VALUES ('Joshua'), ('Adam'), ('Aidan'), ('Kelly'), ('Benjamin'), ('RolAND'), ('David'),('Esthela');


CREATE TABLE transactions( id serial PRIMARY KEY, -- serial / auto-increment
 name varchar NOT NULL REFERENCES accounts, -- Foreign Key
 amount numeric(9, 2) NOT NULL,
                      post_time timestamptz NOT NULL -- timestamp [ (p) ] WITH time zone  / date AND time, including time zone
);


CREATE INDEX ON transactions (name);


CREATE INDEX ON transactions (post_time);

WITH r AS
  ( SELECT (rANDom() * 7)::bigint AS account_offSET
   FROM generate_series(1, 350))
INSERT INTO transactions(name, amount, post_time)
SELECT
  (SELECT name
   FROM accounts
   OFFSET account_offSET
   LIMIT 1), ((rANDom()-0.5)*1000)::numeric(8, 2),
             CURRENT_TIMESTAMP + '90 days'::interval - (rANDom()*1000 || ' days')::interval
FROM r ;


CREATE VIEW account_balances AS
SELECT name,
       COALESCE( SUM(amount) filter (
                                     WHERE post_time <= CURRENT_TIMESTAMP), 0 ) AS balance
FROM accounts
LEFT JOIN transactions USING(name)
GROUP BY name;


SELECT *
FROM account_balances
WHERE balance < 0;

-- materialized view (a snapshot of a query saved INTO a TABLE)

CREATE materialized VIEW account_balances_mat_one AS
SELECT name,
       COALESCE( SUM(amount) filter (
                                     WHERE post_time <= CURRENT_TIMESTAMP), 0 ) AS balance
FROM accounts
LEFT JOIN transactions USING(name)
GROUP BY name;


CREATE INDEX ON account_balances_mat_one (name);


CREATE INDEX ON account_balances_mat_one (balance);


SELECT *
FROM account_balances_mat_one < 0;


INSERT INTO transactions(name, amount, post_time)
VALUES ('Benjamin',
        1000,
        NOW());

-- refresh all rows
refresh materialized VIEW account_balances_mat_one;

-- eager materialized view
-- TRIGGER - on account insertion an account_balances record WITH a zero balance for the new account is created

CREATE TABLE eager_account_balances
  ( name varchar PRIMARY KEY REFERENCES accounts ON UPDATE CASCADE ON DELETE CASCADE,
    balance numeric(9, 2) NOT NULL DEFAULT 0);


CREATE INDEX ON eager_account_balances (balance);


CREATE FUNCTION eager_account_INSERT() RETURNS TRIGGER SECURITY DEFINER LANGUAGE PLPGSQL AS $$
  begin
    INSERT INTO account_balances(name) VALUES(new.name);
    return new;
  END;
$$;


CREATE TRIGGER account_INSERT AFTER
INSERT ON accounts
FOR EACH ROW EXECUTE PROCEDURE eager_account_INSERT();


CREATE FUNCTION eager_refresh_account_balance(_name varchar) RETURNS void SECURITY DEFINER LANGUAGE SQL AS $$
  UPDATE eager_account_balances
  SET balance=
    (
      SELECT SUM(amount)
      FROM transactions
      WHERE eager_account_balances.name=transactions.name
        AND post_time <= current_timestamp
    )
  WHERE name=_name;
$$;


CREATE FUNCTION eager_transaction_insert() RETURNS TRIGGER SECURITY DEFINER LANGUAGE PLPGSQL AS $$
  begin
    perform eager_refresh_account_balance(new.name);
    return new;
  END;
$$;


CREATE TRIGGER eager_transaction_insert_tr AFTER
INSERT ON transactions
FOR EACH ROW EXECUTE PROCEDURE eager_transaction_INSERT();


INSERT INTO transactions(name, amount, post_time)
VALUES ('Linda',
        555.55,
        NOW());


CREATE FUNCTION eager_transaction_delete() RETURNS TRIGGER SECURITY DEFINER LANGUAGE PLPGSQL AS $$
  begin
    perform eager_refresh_account_balance(old.name);
    return old;
  END;
$$;


CREATE TRIGGER eager_transaction_delete AFTER
DELETE ON transactions
FOR EACH ROW EXECUTE PROCEDURE eager_transaction_delete();


CREATE FUNCTION eager_transaction_update() RETURNS TRIGGER SECURITY DEFINER LANGUAGE PLPGSQL AS $$
  begin
    if old.name!=new.name THEN
      perform eager_refresh_account_balance(old.name);
    END if;

    perform eager_refresh_account_balance(new.name);
    return new;
  END;
$$;


CREATE TRIGGER eager_transaction_update_tr AFTER
UPDATE ON transactions
FOR EACH ROW EXECUTE PROCEDURE eager_transaction_UPDATE();

-- CREATE the balance rows

INSERT INTO eager_account_balances(name)
SELECT name
FROM accounts;

-- Refresh the balance rows

SELECT eager_refresh_account_balance(name)
FROM accounts;

SELECT *
FROM eager_account_balances
WHERE balance < 0;
