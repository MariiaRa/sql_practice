--Example AFTER INSERT
CREATE TABLE test (id SERIAL, name varchar(50) NOT NULL, dep varchar(50) NOT NULL, salary INTEGER NOT NULL);

CREATE TABLE test_log (user_id INTEGER NOT NULL, salary INTEGER NOT NULL, edittime DATE NOT NULL);

CREATE OR REPLACE FUNCTION rec_insert()
  RETURNS trigger AS
$$
BEGIN
         INSERT INTO test_log(user_id,salary,edittime)
         VALUES(NEW.id,NEW.salary,current_date);
     RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER ins_same_rec
  AFTER INSERT
  ON test
  FOR EACH ROW
  EXECUTE PROCEDURE rec_insert();


INSERT INTO test VALUES(1, 'David', 'Dep0', 25000);

INSERT INTO test VALUES(2, 'Kelly', 'Dep0', 55000);

INSERT INTO test VALUES(3, 'Sasha', 'Dep1', 25000);

SELECT * FROM test_log;


--Example BEFORE INSERT 

CREATE OR REPLACE FUNCTION befo_insert()
  RETURNS trigger AS
$$
BEGIN
NEW.name = LTRIM(NEW.name);
NEW.dep = LTRIM(NEW.dep);
RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER checl_values
  BEFORE INSERT
  ON test
  FOR EACH ROW
  EXECUTE PROCEDURE befo_insert();

--Example AFTER UPDATE

ALTER TABLE test_log ADD COLUMN description text;

CREATE OR REPLACE FUNCTION aft_update()
  RETURNS trigger AS
$$
BEGIN
INSERT into test_log VALUES (NEW.id,NEW.salary,current_date, CONCAT('Update employee record ',
         OLD.name,' previous salary: ',OLD.salary,', present salary: ',
         NEW.salary));
RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER update_log
  AFTER UPDATE
  ON test
  FOR EACH ROW
  EXECUTE PROCEDURE aft_update();

UPDATE test SET salary = salary + 123;

--Example AFTER DELETE 

CREATE OR REPLACE FUNCTION aft_delete()
  RETURNS trigger AS
$$
BEGIN
INSERT into test_log VALUES (OLD.id,OLD.salary,current_date, CONCAT('Update employee ',
         OLD.NAME,' record, from department ',OLD.dep,' -> Deleted on ',
         NOW()));
RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE TRIGGER delete_employee
  AFTER DELETE
  ON test
  FOR EACH ROW
  EXECUTE PROCEDURE aft_delete();

