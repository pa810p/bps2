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

DROP TABLE IF EXISTS norms;
DROP SEQUENCE IF EXISTS norms_id_seq;
DROP INDEX IF EXISTS norms_name_idx;
DROP INDEX IF EXISTS sugar_stomach_idx;

CREATE SEQUENCE norms_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS norms (
  id int4 DEFAULT nextval('norms_id_seq') NOT NULL,
  name TEXT,
  human TEXT,
  vmin INTEGER,
  vmax INTEGER
);

CREATE UNIQUE index norms_name_idx ON norms (name, human);

INSERT INTO norms (name, human, vmin, vmax) VALUES ('systolic', 'm', 100, 140);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('systolic', 'f', 100, 140);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('diastolic', 'm', 60, 100);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('diastolic', 'f', 60, 100);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('pulse', 'm', 60, 90);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('pulse', 'f', 60, 90);

INSERT INTO norms (name, human, vmin, vmax) VALUES ('sugar empty', 'm', 50, 99); -- before eat
INSERT INTO norms (name, human, vmin, vmax) VALUES ('sugar full', 'm', 50, 149); -- after eat

INSERT INTO norms (name, human, vmin, vmax) VALUES ('urine acid', 'm', 300, 360);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('urine acid', 'f', 240, 300);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('urine_acid', 'c', 210, 240);

INSERT INTO norms (name, human, vmin, vmax) VALUES ('cholesterol', 'm', 50, 518);
INSERT INTO norms (name, human, vmin, vmax) VALUES ('cholesterol', 'f', 50, 518);

ALTER TABLE sugar ADD COLUMN stomach TEXT;

CREATE INDEX sugar_stomach_idx ON sugar(stomach);
