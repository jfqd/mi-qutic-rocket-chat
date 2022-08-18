# Changelog

## 3.18.7

* change numbering schema
* build image for Rocket.Chat 3.18.7
* remove nginx redirect

## 20210413.17

* use latest Rocket.Chat 5.0.2
* add nginx redirect

## 20210413.16

* use latest Rocket.Chat 4.8.3
* autocleanup after build
* move hubot setup to provision time

## 20210413.15

* use latest Rocket.Chat 4.6.4
* patch out "Go full featured"
* migrate mongodb to v4.4
* fix bash path

## 20210413.14

* use latest Rocket.Chat 4.6.3
* disable surveys

## 20210413.13

* use latest Rocket.Chat 4.5.3
* fix nginx logrotation
* backup filesystem-uploads too
* migrate uploads to filesystem
* hardening ports

## 20210413.12

* use latest Rocket.Chat 4.4.0
* update node to 14.18.2
* include engine in version output
* always backup database

## 20210413.11

* use latest Rocket.Chat 4.3.2
* use latest lx-base image
* add after-install cleanup script
* skip nextcloud backup if url is mising

## 20210413.10

* use latest Rocket.Chat 4.3.0
* log rocketchat nginx requests
* http-auth protected backup url
* allow up to 4 node processes
* include htop package

## 20210413.9

* use latest Rocket.Chat 4.2.0
* set mongodb-engine to wiredTiger

## 20210413.8

* use latest Rocket.Chat 4.1.0
* migrate to mongodb version 4.2

## 20210413.7

* use latest Rocket.Chat 4.0.1

## 20210413.6

* use latest Rocket.Chat 3.18.0
* ensure proper backup-upload
* fix zabbix update issue

## 20210413.5

* use latest Rocket.Chat 3.17.0

## 20210413.4

* use latest Rocket.Chat 3.17.0
* add own nginx.service

## 20210413.3

* use latest base image 20210413.2
* add nfs backup option
* ensure rocketchat@3001 service on restart
* increase value for client_max_body_size
* add worker_rlimit_nofile to nginx.conf
* add nginx base config

## 20210413.2

* use latest Rocket.Chat 3.15.0

## 20210413.1

* use latest Rocket.Chat 3.14.4
* split mongo-backup
* backup external-upload 
* script for rc-version
* setup jitsi for Rocket.Chat

## 20210413.0

* use latest Rocket.Chat 3.14.0
* switch to ubuntu 20.04

## 20180404.23

* use latest Rocket.Chat 3.13.3
* update node to 12.21.0
* add option for filesystem_restore

## 20180404.22

* use latest Rocket.Chat 3.13.1

## 20180404.21

* use latest Rocket.Chat 3.13.0

## 20180404.20

* use latest Rocket.Chat 3.12.1
* use latest lx-base 20180404.5

## 20180404.19

* use latest Rocket.Chat 3.10.3
* fix typo in sed command
* create a bash_history for convenience
* remove dump- and log-files

## 20180404.18

* use latest Rocket.Chat 3.9.4

## 20180404.17

* use latest Rocket.Chat 3.9.3
* fixes XSS CVS

## 20180404.16

* use latest Rocket.Chat 3.9.1
* update node to 12.18.4
* Add hubot option

## 20180404.15

* use latest Rocket.Chat 3.9.0
* update Rocket.Chat settings
* add uptodate script

## 20180404.14

* use latest Rocket.Chat 3.7.1

## 20180404.13

* use latest Rocket.Chat 3.6.3

## 20180404.12

* use latest Rocket.Chat 3.6.0
* add option to start more than one node instance

## 20180404.11

* use latest Rocket.Chat 3.5.1
* add api-config option
* increase max upload

## 20180404.10

* use latest Rocket.Chat 3.2.2

## 20180404.9

* use latest Rocket.Chat 3.0.2
* use latest base image
* remove munin and nagios

## 20180404.8

* add rocketchat-database option
* increase nproc for mongod
* setup mongodb nrpe plugin
* drop exising databases before mongorestore

## 20180404.7

* use latest Rocket.Chat 2.2.0

## 20180404.6

* setup monodump backup to nextcloud
* add mongodump re-import option

## 20180404.5

* use latest Rocket.Chat 2.0.0

## 20180404.4

* use latest Rocket.Chat 0.74.3

## 20180404.3

* start all services
* add munin plugin for mongodb

## 20180404.2

* first rocket-chat release
