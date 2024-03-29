#!/usr/bin/bash

if [[ -n $(grep "engine: mmapv1" /etc/mongod.conf) ]]; then
  sed -i "s/  engine: mmapv1/  engine: wiredTiger/" /etc/mongod.conf
fi

if /native/usr/sbin/mdata-get filesystem_restore 1>/dev/null 2>&1; then
  if [[ $(/native/usr/sbin/mdata-get filesystem_restore) = "true" ]]; then
    while [[ ! -f /usr/local/var/tmp/restore_complete ]]; do
      sleep 20
    done
    chown -R mongodb:mongodb /var/lib/mongodb
  fi
fi

if /native/usr/sbin/mdata-get mongodb_url 1>/dev/null 2>&1; then
  MONGO_URL=$(/native/usr/sbin/mdata-get mongodb_url)
  sed -i \
      -e "s#Environment=MONGO_URL=mongodb://127.0.0.1:27017/rocket#Environment=MONGO_URL=${MONGO_URL}#" \
      /etc/systemd/system/rocketchat.service
  systemctl stop mongod || true
else
  # IMPORTANT: service name is: mongod
  systemctl enable mongod || true
  systemctl start mongod || true
  sleep 10
  
  if [[ -x /usr/bin/mongosh ]]; then
    mongosh --quiet --eval "printjson(rs.initiate())"
  else
    mongo --eval "printjson(rs.initiate())"
  fi
  
  # mongodump re-import option
  if /native/usr/sbin/mdata-get mongodump_url 1>/dev/null 2>&1; then
    MONGODUMP_URL=$(/native/usr/sbin/mdata-get mongodump_url)
    mkdir -p /var/local/mongodump
    curl -s -L -o /var/local/mongodump/mongodump.tar.gz "$MONGODUMP_URL"
    ( cd /var/local/mongodump/ ; tar xf /var/local/mongodump/mongodump.tar.gz )
    # use drop on existing databases
    mongorestore --drop /var/local/mongodump/*.mongodump || true
    rm -rf /var/local/mongodump/*.mongodump || true
    rm -rf /var/local/mongodump/*.tar.gz || true
  fi

  # setup monodump backup to nextcloud
  if /native/usr/sbin/mdata-get nextcloud_url 1>/dev/null 2>&1; then
    NEXTCLOUD_URL=$(/native/usr/sbin/mdata-get nextcloud_url)
    NEXTCLOUD_USR=$(/native/usr/sbin/mdata-get nextcloud_user)
    NEXTCLOUD_PWD=$(/native/usr/sbin/mdata-get nextcloud_password)
    WAIT_EXTENSION="-s "
    sed -i \
        -e "s#NEXTCLOUD='https://nextcloud.example.com'#NEXTCLOUD='${NEXTCLOUD_URL}'#" \
        -e "s#nextcloud-username#${NEXTCLOUD_USR}#" \
        -e "s#nextcloud-password#${NEXTCLOUD_PWD}#" \
        /usr/local/bin/mongo-backup
  else
    sed -i \
        -e "s#NEXTCLOUD='https://nextcloud.example.com'#NEXTCLOUD=''#" \
        /usr/local/bin/mongo-backup
  fi
  chmod 0750 /usr/local/bin/mongo-backup

  if [[ ! -e /etc/cron.d/mongo-backup ]]; then
    cat > /etc/cron.d/mongo-backup << EOF
MAILTO=root
#
50 23 * * *     root   /usr/local/bin/mongo-backup ${WAIT_EXTENSION}> /dev/null
# END
EOF
  fi

  
fi