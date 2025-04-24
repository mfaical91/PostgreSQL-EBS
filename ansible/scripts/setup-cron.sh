#!/bin/bash

CRON_CMD="0 2 * * * /usr/bin/ansible-playbook /home/ubuntu/postgres-ebs-backup/ansible/snapshot.yml >> /var/log/postgres_snapshot.log 2>&1"
( crontab -l | grep -v 'snapshot.yml' ; echo "$CRON_CMD" ) | crontab -
echo "[✔] Cron job de backup PostgreSQL installé pour 2h chaque nuit."
