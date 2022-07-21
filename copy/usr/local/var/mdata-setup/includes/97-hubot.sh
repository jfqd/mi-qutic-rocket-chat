#!/usr/bin/bash

if /native/usr/sbin/mdata-get hubot_password 1>/dev/null 2>&1; then
  echo "* Setup hubot"
  addgroup hubot
  adduser --disabled-password --system --quiet --home /var/www/hubot --shell /bin/bash hubot
  adduser hubot hubot
  mkdir -p /var/www/hubot
  su - hubot -c "git clone https://github.com/RocketChat/hubot-rocketchat-boilerplate"
  # https://github.com/RocketChat/hubot-rocketchat/issues/338#issuecomment-734128312
  sed -i \
      -e "s|rocketchat/hubot-rocketchat|git+https://github.com/DeviaVir/hubot-rocketchat.git|" \
      /var/www/hubot/hubot-rocketchat-boilerplate/package.json
  # install dependencies
  su - hubot -c "cd hubot-rocketchat-boilerplate; npm install" || true
  su - hubot -c "cd hubot-rocketchat-boilerplate; npm install --save git@github.com:jfqd/hubot-rundeck.git" || true
  su - hubot -c "cd hubot-rocketchat-boilerplate; npm install --save hubot-rememberto" || true
  cp /usr/local/var/tmp/external-scripts.json /var/www/hubot/hubot-rocketchat-boilerplate/external-scripts.json
  cp /usr/local/var/tmp/hubot_service /etc/systemd/system/hubot.service
fi