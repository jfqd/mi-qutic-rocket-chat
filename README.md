# mi-qutic-rocket-chat

This repository is based on [Joyent mibe](https://github.com/jfqd/mibe).

## description

rocket-chat lx-brand image, with rocket-chat version 0.74.0

## Build Image

```
cd /opt/mibe/repos
/opt/tools/bin/git clone https://github.com/jfqd/mi-qutic-rocket-chat.git
LXBASE_IMAGE_UUID=$(imgadm list | grep qutic-lx-base | tail -1 | awk '{ print $1 }')
TEMPLATE_ZONE_UUID=$(vmadm lookup alias='qutic-lx-template-zone')
../bin/build_lx $LXBASE_IMAGE_UUID $TEMPLATE_ZONE_UUID mi-qutic-rocket-chat && \
  imgadm install -m /opt/mibe/images/qutic-rocket-chat-*-imgapi.dsmanifest \ 
                 -f /opt/mibe/images/qutic-rocket-chat-*.zfs.gz
```