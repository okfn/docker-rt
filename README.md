docker-rt
=========

This is a docker image for running Best Practical's RT (Request Tracker), a
ticket tracking system.

It's currently a work in progress, but it includes

  RT
  nginx
  postfix + spamassassin

And exposes the RT web interface on container port 80 and an RT-connected MTA on
container port 25.

from scratch
------------
Build the postgres image:

```
  cd postgres
  docker build -t pgsql .
  cd ..
```

Start a postgres container:
```
  docker run -d \
    -e POSTGRES_PASSWORD=secret \
    --name rtdb \
    pgsql:latest \
    postgres
```
Build the rt image.

```
docker build -t rt4 .
```

Run a one-off container to configure the database:
```
  docker run \
    --link rtdb:db \
    -e DBA_USER=postgres \
    -e DBA_PASSWORD=secret \
    -e DATABASE_NAME=rt4 \
    -e DATABASE_USER=rt_user \
    -e DATABASE_PASSWORD=rt_pass \
    rt4:latest \
    /usr/bin/rtinit
```

Run a one-off container to load any required arbitrary data into the database
```
docker run \
  --link rtdb:db \
  -e DBA_USER=postgres \
  -e DBA_PASSWORD=secret \
  -e RT_DATAINIT=customdata \
  -v /tmp/import:/import \
  rt4:latest \
  /usr/bin/rtdata
```

Now the database is initialised and you can run RT proper:
```
  docker run -d \
    --link rtdb:db \
    -p 25 \
    -p 80 \
    -e DATABASE_USER=rt_user \
    -e DATABASE_PASSWORD=rt_pass \
    -e DATABASE_NAME=rt4 \
    -e RT_NAME=example.com \
    -e Organization=example.com \
    -e WEB_DOMAIN=tickets.example.com \
    -e WEB_PORT=80 \
    rt4:latest
```

To see the ports on which the web and mail interfaces are exposed, run `docker ps`.

run against a pre-existing database
-----------------------------------

You can provide the DATABASE_HOST directly:
```
  docker run -d \
    -p 25 \
    -p 80 \
    -e DATABASE_HOST=dbserver \
    -e DATABASE_USER=rt_user \
    -e DATABASE_PASSWORD=rt_pass \
    -e DATABASE_NAME=rt4 \
    -e RT_NAME=example.com \
    -e Organization=example.com \
    -e WEB_DOMAIN=tickets.example.com \
    -e WEB_PORT=80 \
    rt4:latest
```
configuration
-------------

This image provides some limited support for customising the deployment using
environment variables. See RT_SiteConfig.pm for details.
