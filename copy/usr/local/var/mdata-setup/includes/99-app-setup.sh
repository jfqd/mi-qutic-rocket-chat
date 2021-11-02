#!/usr/bin/bash

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
else
  RC_DATABASE="rocket"
fi

if /native/usr/sbin/mdata-get rocketchat_api 1>/dev/null 2>&1; then
  if [[ $(/native/usr/sbin/mdata-get rocketchat_api) = "true" ]]; then
    sed -i \
        -e "s:#Environment=CREATE_TOKENS_FOR_USERS=true:Environment=CREATE_TOKENS_FOR_USERS=true:" \
        /etc/systemd/system/rocketchat.service
  fi
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
  systemctl enable rocketchat@3001
  # restart nginx
  sed -i \
      -e "s|  # server 127.0.0.1:3001;|  server 127.0.0.1:3001;|" \
      /etc/nginx/sites-available/rocketchat
  # TODO: maybe start more than two instances
fi

# Restart nginx to load config-changes
systemctl restart nginx

if /native/usr/sbin/mdata-get mongodb_url 1>/dev/null 2>&1; then
  echo "* Skip mongodb settings"
else
  # sleep two minute to ensure db was created
  sleep 120
  cat >> /usr/local/bin/rc-config << EOF
#!/usr/bin/bash
echo "* Enable prometheus node endpoint"
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Prometheus_Enabled"},{ $set: {"value": true} });' || true
echo "* Disable update notification"
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Update_EnableChecker"},{ $set: {"value": false} });' || true
EOF
  chmod +x /usr/local/bin/rc-config
  /usr/local/bin/rc-config || true
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

cat >> /etc/cron.d/restart-rocketchat << EOF
MAILTO=root
#
0 1 1 * *     root   /bin/systemctl restart rocketchat
# END
EOF

if /native/usr/sbin/mdata-get jitsi_url 1>/dev/null 2>&1; then
  echo "* Setup Jitsi Meet for Rocket.Chat"
  JITSI_URL=$(/native/usr/sbin/mdata-get jitsi_url)
  JITSI_APP_ID=$(/native/usr/sbin/mdata-get jitsi_app_id)
  JITSI_APP_SECRET=$(/native/usr/sbin/mdata-get jitsi_app_secret)
  cat >> /usr/local/bin/setup-jitsi-meet << EOF
#!/usr/bin/bash
mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Jitsi_Domain"},{ $set: {"value": "${JITSI_URL}"} });'
mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Jitsi_Application_ID"},{ $set: {"value": "${JITSI_APP_ID}"} });'
mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Jitsi_Application_Secret"},{ $set: {"value": "${JITSI_APP_SECRET}"} });'
mongo --quiet --eval 'db.getSiblingDB("rocket").rocketchat_settings.updateOne({ _id: "Jitsi_Enabled"},{ $set: {"value": true} });'

EOF
  chmod 0700 /usr/local/bin/setup-jitsi-meet
  /usr/local/bin/setup-jitsi-meet || true
fi

# journalctl -f -u rocketchat
# systemctl status rocketchat
# systemctl stop rocketchat