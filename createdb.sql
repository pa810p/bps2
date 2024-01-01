DROP TABLE IF EXISTS pressure;
DROP SEQUENCE IF EXISTS pressure_id_seq;

CREATE SEQUENCE pressure_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS pressure (
	id int4 DEFAULT nextval('pressure_id_seq') NOT NULL,
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

DROP TABLE IF EXISTS urine_acid;
DROP SEQUENCE IF EXISTS urine_acid_id_seq;

CREATE SEQUENCE urine_acid_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS urine_acid (
  id int4 DEFAULT nextval('urine_acid_id_seq') NOT NULL,
  datetime TIMESTAMP NOT NULL UNIQUE,
  urine INTEGER NOT NULL,
  comment TEXT DEFAULT ''
);

DROP TABLE IF EXISTS cholesterol;
DROP SEQUENCE IF EXISTS cholesterol_id_seq;

CREATE SEQUENCE cholesterol_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS cholesterol (
  id int4 DEFAULT nextval('cholesterol_id_seq') NOT NULL,
  datetime TIMESTAMP NOT NULL UNIQUE,
  cholesterol INTEGER NOT NULL,
  comment TEXT DEFAULT ''
);

