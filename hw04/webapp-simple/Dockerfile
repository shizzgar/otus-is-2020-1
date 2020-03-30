
FROM python:3.8.2-alpine3.11

RUN adduser -h /home/webapp -D -s /bin/bash webapp

RUN mkdir -p /run/app/data && chown -R webapp /run/app/data

WORKDIR /app
COPY requirements.txt .
COPY ./server/* .
COPY ./entrypoint .
RUN     chmod +x ./entrypoint && chown -R webapp:webapp $(pwd)/*

RUN YARL_NO_EXTENSIONS=1 MULTIDICT_NO_EXTENSIONS=1 pip3.8 install -r requirements.txt
 

HEALTHCHECK --interval=5m --timeout=3s CMD curl -f http://localhost:8188/ || exit 1

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

EXPOSE 8188

USER webapp

ENTRYPOINT sh ./entrypoint