# Docker-Postgres

Build like so:

```
docker build -t pgsql .
```

Run it like so:

```
docker run -d \
  -e POSTGRES_PASSWORD=secret \
  --name mydb \
  pgsql:latest
```
