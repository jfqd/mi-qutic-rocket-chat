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

if /native/usr/sbin/mdata-get rocketchat_adm_usr 1>/dev/null 2>&1; then
  RC_ADM_USR=$(/native/usr/sbin/mdata-get rocketchat_adm_usr)
  RC_ADM_PWD=$(/native/usr/sbin/mdata-get rocketchat_adm_pwd)
  RC_ADM_EMAIL=$(/native/usr/sbin/mdata-get rocketchat_adm_email)
  sed -i \
      -e "s|#Environment=OVERWRITE_SETTING_Show_Setup_Wizard=completed|Environment=OVERWRITE_SETTING_Show_Setup_Wizard=completed|" \
      -e "s|#Environment=INITIAL_USER=yes|Environment=INITIAL_USER=yes|" \
      -e "s|#Environment=ADMIN_USERNAME=adm_usr|Environment=ADMIN_USERNAME=${RC_ADM_USR}|" \
      -e "s|#Environment=ADMIN_PASS=adm_pwd|Environment=ADMIN_PASS=${RC_ADM_PWD}|" \
      -e "s|#Environment=ADMIN_EMAIL=adm_email|Environment=ADMIN_EMAIL=${RC_ADM_EMAIL}|" \
      -e "s|#Environment=OVERWRITE_SETTING_From_Email=adm_email|Environment=OVERWRITE_SETTING_From_Email=${RC_ADM_EMAIL}|" \
      /etc/systemd/system/rocketchat.service
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
fi
if [[ $(/native/usr/sbin/mdata-get rocketchat_instances) > 2 ]]; then
  systemctl daemon-reload
  systemctl start rocketchat@3002
  systemctl enable rocketchat@3002
  # restart nginx
  sed -i \
      -e "s|  # server 127.0.0.1:3002;|  server 127.0.0.1:3002;|" \
      /etc/nginx/sites-available/rocketchat
fi
if [[ $(/native/usr/sbin/mdata-get rocketchat_instances) > 3 ]]; then
  systemctl daemon-reload
  systemctl start rocketchat@3003
  systemctl enable rocketchat@3003
  # restart nginx
  sed -i \
      -e "s|  # server 127.0.0.1:3003;|  server 127.0.0.1:3003;|" \
      /etc/nginx/sites-available/rocketchat
fi

# echo "* Calculate workers-processes and -connections"
# # ulimit -n => 1048576
# MEMCAP=$(cat /proc/meminfo | grep MemTotal | awk '{ print $2 }' | awk '{ printf "%d", $1/1024 }');
# NGINX_WORKER=1
# [[ ${MEMCAP} -ge 2560 ]]  && NGINX_WORKER=1
# [[ ${MEMCAP} -ge 6144 ]]  && NGINX_WORKER=1
# [[ ${MEMCAP} -ge 10240 ]] && NGINX_WORKER=2

# Restart nginx to load config-changes
systemctl restart nginx

# if /native/usr/sbin/mdata-get mongodb_url 1>/dev/null 2>&1; then
#   echo "* Skip mongodb settings"
# else
#   # sleep two minute to ensure db was created
#   sleep 120
#   cat >> /usr/local/bin/rc-config << EOF
# #!/usr/bin/bash
# echo "* Disable free cloud-based monitoring service"
# mongo --quiet --eval 'db.disableFreeMonitoring();' || true
# echo "* Enable prometheus node endpoint"
# mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Prometheus_Enabled"},{ \$set: {"value": true} });' || true
# echo "* Disable update notification"
# mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Update_EnableChecker"},{ \$set: {"value": false} });' || true
# echo "* Disable surveys"
# mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "NPS_survey_enable"},{ \$set: {"value": false} });' || true
# EOF
#   chmod +x /usr/local/bin/rc-config
#   /usr/local/bin/rc-config || true
# fi

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
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Jitsi_Domain"},{ \$set: {"value": "${JITSI_URL}"} });'
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Jitsi_Application_ID"},{ \$set: {"value": "${JITSI_APP_ID}"} });'
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Jitsi_Application_Secret"},{ \$set: {"value": "${JITSI_APP_SECRET}"} });'
mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "Jitsi_Enabled"},{ \$set: {"value": true} });'

EOF
  chmod 0700 /usr/local/bin/setup-jitsi-meet
  /usr/local/bin/setup-jitsi-meet || true
fi

# echo "* Migrate upload-storage to FileSystem"
# cat >> /usr/local/bin/migrate-rc-to-filesystempath << EOF
# #!/usr/bin/bash
# 
# echo "* Set Storage to FileSystem "
# mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "FileUpload_Storage_Type"},{ \$set: {"value": "FileSystem"} });' || true
# echo "* Set Upload path"
# mongo --quiet --eval 'db.getSiblingDB("${RC_DATABASE}").rocketchat_settings.updateOne({ _id: "FileUpload_FileSystemPath"},{ \$set: {"value": "/var/www/rocket/upload"} });' || true
# 
# EOF
# chmod 0700 /usr/local/bin/migrate-rc-to-filesystempath
# /usr/local/bin/migrate-rc-to-filesystempath

echo "* Create http-basic password for backup area"
if [[ ! -f /etc/nginx/.htpasswd ]]; then
  if /native/usr/sbin/mdata-get rocketchat_backup_pwd 1>/dev/null 2>&1; then
    /native/usr/sbin/mdata-get rocketchat_backup_pwd | shasum | awk '{print $1}' | htpasswd -c -i /etc/nginx/.htpasswd "rc-backup"
    chmod 0640 /etc/nginx/.htpasswd
    chown root:www-data /etc/nginx/.htpasswd
    mkdir -p /var/local/mongodump/
  fi
fi

# journalctl -f -u rocketchat
# systemctl status rocketchat
# systemctl stop rocketchat