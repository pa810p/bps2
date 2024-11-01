#!/usr/bin/env bash

source setup.sh

@test "should list norms" {
  init_sqlite_database

  RUN $BLOOD
}