FROM postgres:17

RUN mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-orig.sh

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv curl net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.9/etcd-v3.5.9-linux-amd64.tar.gz -o etcd.tar.gz \
    && tar xzf etcd.tar.gz \
    && cp etcd-v3.5.9-linux-amd64/etcd /usr/local/bin/ \
    && cp etcd-v3.5.9-linux-amd64/etcdctl /usr/local/bin/ \
    && rm -rf /tmp/etcd*

RUN python3 -m venv /opt/patroni-venv
ENV PATH="/opt/patroni-venv/bin:$PATH"
RUN pip install --no-cache-dir patroni[etcd]==3.2.0 psycopg2-binary

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5432 8008

ENTRYPOINT ["/entrypoint.sh"]