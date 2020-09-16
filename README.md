`docker-compose.yml`
```yaml
sphinxsearch:
     image: michalizewski/sphinxsearch-2.2
     container_name: sphinxsearch-2.2
     restart: always
     ports:
      - 127.0.0.1:9306:9306
      - 127.0.0.1:9312:9312
     volumes:
      - /etc/docker/sphinxsearch/etc:/etc/sphinx
      - /etc/docker/sphinxsearch/cron:/var/spool/cron
      - /etc/docker/sphinxsearch/data:/var/lib/sphinx
      - /etc/docker/sphinxsearch/log:/var/log/sphinx
```

