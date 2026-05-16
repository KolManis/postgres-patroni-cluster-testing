#!/bin/bash
set -e

# Очистка старых данных PostgreSQL
rm -rf /var/lib/postgresql/data/* 2>/dev/null || true
mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql

# Очистка etcd
rm -rf /var/lib/etcd/* 2>/dev/null || true
mkdir -p /var/lib/etcd

# Запуск etcd от root
/usr/local/bin/etcd --name etcd \
  --data-dir /var/lib/etcd \
  --listen-client-urls http://0.0.0.0:2379 \
  --advertise-client-urls http://127.0.0.1:2379 \
  --listen-peer-urls http://0.0.0.0:2380 \
  --initial-advertise-peer-urls http://127.0.0.1:2380 \
  --initial-cluster etcd=http://127.0.0.1:2380 \
  --initial-cluster-state new \
  --enable-v2=true > /var/log/etcd.log 2>&1 &

# Ждём etcd
echo "Waiting for etcd..."
for i in 1 2 3 4 5 6 7 8 9 10; do
  sleep 1
  curl -s http://127.0.0.1:2379/health && break
done

# Запуск Patroni от пользователя postgres
echo "Starting Patroni as postgres user..."
su - postgres -c "/opt/patroni-venv/bin/patroni /etc/patroni.yml"