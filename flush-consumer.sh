#!/bin/bash

docker compose exec db psql -Uorodbuser orodb -c "TRUNCATE TABLE oro_message_queue CASCADE;"
docker compose exec db psql -Uorodbuser orodb -c "TRUNCATE TABLE oro_message_queue_job CASCADE"
docker compose exec db psql -Uorodbuser orodb -c "TRUNCATE TABLE oro_message_queue_job_unique CASCADE"
docker compose exec db psql -Uorodbuser orodb -c "TRUNCATE TABLE oro_message_queue_state CASCADE"
