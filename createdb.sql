DROP TABLE IF EXISTS blood;
DROP SEQUENCE IF EXISTS blood_id_seq;

CREATE SEQUENCE blood_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS blood (
	id int4 DEFAULT nextval('blood_id_seq') NOT NULL,
	datetime TIMESTAMP NOT NULL UNIQUE,
	systolic INTEGER NOT NULL, 
	diastolic INTEGER NOT NULL, 
	pulse INTEGER NOT NULL, 
	comment TEXT DEFAULT ''
);

DROP TABLE IF EXISTS sugar;
DROP SEQUENCE IF EXISTS sugar_id_seq;

CREATE SEQUENCE sugar_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS sugar (
  id int4 DEFAULT nextval('sugar_id_seq') NOT NULL,
	datetime TIMESTAMP NOT NULL UNIQUE,
  sugar INTEGER NOT NULL,
  comment TEXT DEFAULT ''
);


