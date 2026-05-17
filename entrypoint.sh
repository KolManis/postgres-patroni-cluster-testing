#!/bin/bash
set -e

# Создаём директорию данных с правильными правами
mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql
chmod 0700 /var/lib/postgresql/data

# Очистка старых данных только если нет PG_VERSION
if [ ! -f /var/lib/postgresql/data/PG_VERSION ]; then
    rm -rf /var/lib/postgresql/data/* 2>/dev/null || true
fi

# Создаём YAML-файл из переменных окружения
cat > /tmp/patroni.yml << EOF
scope: postgres-cluster
name: ${PATRONI_NAME}

restapi:
  listen: 0.0.0.0:8008
  connect_address: ${PATRONI_NAME}:8008

etcd:
  hosts: etcd:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        max_connections: 100
        max_wal_senders: 5
        wal_keep_size: 64
        max_replication_slots: 5
        archive_mode: "on"
        archive_timeout: 1800
  initdb:
  - auth-host: md5
  - auth-local: trust
  pg_hba:
  - host replication replicator 0.0.0.0/0 md5
  - host all all 0.0.0.0/0 md5

postgresql:
  listen: 0.0.0.0:5432
  connect_address: ${PATRONI_NAME}:5432
  data_dir: /var/lib/postgresql/data
  bin_dir: /usr/lib/postgresql/17/bin
  authentication:
    replication:
      username: replicator
      password: replpass
    superuser:
      username: postgres
      password: postgres

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
EOF

# Запуск Patroni
su - postgres -c "/opt/patroni-venv/bin/patroni /tmp/patroni.yml"