DROP TABLE IF EXISTS norms;
DROP SEQUENCE IF EXISTS norms_id_seq;

DROP INDEX IF EXISTS norms_name_idx;

CREATE SEQUENCE norms_id_seq start 1 increment 1 minvalue 1 cache 1;
CREATE UNIQUE index norms_name_idx ON norms (name, human);

CREATE TABLE IF NOT EXISTS norms (
  id int4 DEFAULT nextval('norms_id_seq') NOT NULL,
  name TEXT,
  human TEXT,
  vmin INTEGER,
  vmax INTEGER
);

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

INSERT INTO norms (name, human, vmin, vmax) VALUES ('cholesterol', 'm', 0, 518);

CREATE UNIQUE index norms_name_idx ON norms (name, human);

ALTER TABLE sugar ADD COLUMN stomach TEXT;
UPDATE sugar SET stomach='f' WHERE to_char(datetime, 'HH24:MI') > '10:00';
UPDATE sugar SET stomach='e' WHERE to_char(datetime, 'HH24:MI') < '10:00';

DROP INDEX IF EXISTS sugar_stomach_idx;
CREATE INDEX sugar_stomach_idx ON sugar(stomach);
