DROP TABLE IF EXISTS cholesterol;
DROP SEQUENCE IF EXISTS cholesterol_id_seq;

CREATE SEQUENCE cholesterol_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS cholesterol (
  id int4 DEFAULT nextval('cholesterol_id_seq') NOT NULL,
  datetime TIMESTAMP NOT NULL UNIQUE,
  cholesterol INTEGER NOT NULL,
  comment TEXT DEFAULT ''
);

