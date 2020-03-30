
FROM FROM python:3.7-slim-buster
ENV PYTHONUNBUFFERED 1

COPY requirements.txt /app/
COPY ./client/* /app/

WORKDIR /app

RUN pip3.7 install -r requirements.txt

EXPOSE 8188

CMD 