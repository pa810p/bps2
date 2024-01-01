DROP TABLE IF EXISTS urine_acid;
DROP SEQUENCE IF EXISTS urine_acid_id_seq;

CREATE SEQUENCE urine_acid_id_seq start 1 increment 1 minvalue 1 cache 1;

CREATE TABLE IF NOT EXISTS urine_acid (
  id int4 DEFAULT nextval('urine_acid_id_seq') NOT NULL,
  datetime TIMESTAMP NOT NULL UNIQUE,
  urine INTEGER NOT NULL,
  comment TEXT DEFAULT ''
);

ALTER TABLE blood RENAME TO pressure;

