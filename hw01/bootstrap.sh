#!/bin/bash

  if ! id -u otus > /dev/null 2>&1; then
    useradd -m otus    
  fi  
  echo -e 'vic!!vak\nvic!!vak' | passwd otus >/dev/null

  if ! id -u otus2 > /dev/null 2>&1; then
    useradd -m otus2 
  fi
  echo -e 'vic!!vak\nvic!!vak' | passwd otus2 >/dev/null
  
  if ! id -u otus3 > /dev/null 2>&1; then
        useradd -m otus3 
  fi 
  echo -e 'vic!!vak\nvic!!vak' | passwd otus3 >/dev/null

  cp -r /home/$1/.ssh /home/otus/.ssh
  cp -r /home/$1/.ssh /home/otus2/.ssh
  cp -r /home/$1/.ssh /home/otus3/.ssh

  chown otus:otus -R /home/otus/.ssh
  chown otus2:otus2 -R /home/otus2/.ssh
  chown otus3:otus3 -R /home/otus3/.ssh
