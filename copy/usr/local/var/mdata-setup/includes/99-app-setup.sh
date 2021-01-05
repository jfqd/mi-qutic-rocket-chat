#!/bin/bash

if /native/usr/sbin/mdata-get mail_smarthost 1>/dev/null 2>&1; then
  MAIL_UID=$(/native/usr/sbin/mdata-get mail_auth_user)
  MAIL_PWD=$(/native/usr/sbin/mdata-get mail_auth_pass)
  MAIL_HOST=$(/native/usr/sbin/mdata-get mail_smarthost)
  sed -i \
      -e "s#smtp://noreply%40example.com:password@mail.example.com:587#smtp://${MAIL_UID}:${MAIL_PWD}@${MAIL_HOST}#" \
      /etc/systemd/system/rocketchat.service
fi

if /native/usr/sbin/mdata-get rocketchat_domain 1>/dev/null 2>&1; then
  RC_DOMAIN=$(/native/usr/sbin/mdata-get rocketchat_domain)
  sed -i \
      -e "s#ROOT_URL=https://rocket-chat.example.com/#ROOT_URL=${RC_DOMAIN}#" \
      /etc/systemd/system/rocketchat.service
fi

if /native/usr/sbin/mdata-get rocketchat_database 1>/dev/null 2>&1; then
  RC_DATABASE=$(/native/usr/sbin/mdata-get rocketchat_database)
  sed -i \
      -e "s:27017/rocket?replicaSet=rs01:27017/${RC_DATABASE}?replicaSet=rs01:" \
      /etc/systemd/system/rocketchat.service
fi

if [[ $(/native/usr/sbin/mdata-get rocketchat_api) = "true" ]]; then
  sed -i \
      -e "s:#Environment=CREATE_TOKENS_FOR_USERS=true:Environment=CREATE_TOKENS_FOR_USERS=true:" \
      /etc/systemd/system/rocketchat.service
fi

# start service
# chmod 0640 /etc/systemd/system/rocketchat.service
systemctl daemon-reload
systemctl enable rocketchat.service
systemctl start rocketchat

if [[ $(/native/usr/sbin/mdata-get rocketchat_instances) > 1 ]]; then
  # https://docs.rocket.chat/installation/manual-installation/multiple-instances-to-improve-performance
  cp /etc/systemd/system/rocketchat.service /etc/systemd/system/rocketchat@.service
  sed -i \
      -e "s:Environment=PORT=3000:Environment=PORT=%I:" \
      -e "s:WantedBy=multi-user.target:WantedBy=rocketchat.service:" \
      /etc/systemd/system/rocketchat@.service
  # start second instance
  systemctl daemon-reload
  systemctl start rocketchat@3001
  # restart nginx
  sed -i \
      -e "s|  # server 127.0.0.1:3001;|  server 127.0.0.1:3001;|" \
      /etc/nginx/sites-available/rocketchat
  systemctl restart nginx
  # TODO: maybe start more than two instances
fi

if /native/usr/sbin/mdata-get mongodb_url 1>/dev/null 2>&1; then
  echo "* Skip mongodb settings"
else
  # sleep two minute to ensure db was created
  sleep 120
  echo "* Enable prometheus node endpoint"
  mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Prometheus_Enabled"},{ $set: {"value": true} });' || true
  echo "* Disable update notification"
  mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Update_EnableChecker"},{ $set: {"value": false} });' || true
fi

if /native/usr/sbin/mdata-get hubot_password 1>/dev/null 2>&1; then
  # todo create hubot user and room in rocketchat if missing
  # mongo --quiet --eval 'db.getSiblingDB("rocket").tbd' || true
  echo "* Enable hubot"
  RC_DOMAIN=$(/native/usr/sbin/mdata-get rocketchat_domain)
  HUBOT_PWD=$(/native/usr/sbin/mdata-get hubot_password)
  sed -i \
      -e "s|Environment=ROCKETCHAT_URL=myserver.com|Environment=ROCKETCHAT_URL=${RC_DOMAIN}|" \
      -e "s|Environment=ROCKETCHAT_PASSWORD=mypassword|Environment=ROCKETCHAT_PASSWORD=${HUBOT_PWD}|" \
      /etc/systemd/system/hubot.service
  # start hubot
  # chmod 0640 /etc/systemd/system/hubot.service
  systemctl daemon-reload
  systemctl enable hubot.service || true
  systemctl start hubot || true
fi

# journalctl -f -u rocketchat
# systemctl status rocketchat
# systemctl stop rocketchat