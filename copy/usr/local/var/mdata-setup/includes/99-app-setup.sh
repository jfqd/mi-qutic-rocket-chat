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

# start service
systemctl daemon-reload
systemctl enable rocketchat.service
systemctl start rocketchat

# journalctl -f -u rocketchat
# systemctl status rocketchat
# systemctl stop rocketchat