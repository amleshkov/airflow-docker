# airflow-docker
Airflow 1.10 + Mariadb Docker setup

1. Create shared storage for containers

```
mkdir /tmp/airflow
sudo chown -R 50000:50000 /tmp/airflow
```

2. Run compose

```docker-compose run initdb && docker-compose up```

