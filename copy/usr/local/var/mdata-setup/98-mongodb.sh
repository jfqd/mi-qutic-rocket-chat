#!/bin/bash

if mdata-get mongodb_url 1>/dev/null 2>&1; then
  MONGO_URL=$(mdata-get mongodb_url)
  gsed -i \
       -e "s#Environment=MONGO_OPLOG_URL=mongodb://127.0.0.1:27017/rocket#Environment=MONGO_OPLOG_URL={MONGO_URL}#" \
       -e "s#Environment=MONGO_URL=mongodb://127.0.0.1:27017/rocket#Environment=MONGO_URL={MONGO_URL}#" \
       /etc/systemd/system/rocketchat.service
  
  systemctl start mongodb
  echo 'rs.initiate()' | mongo
fi
