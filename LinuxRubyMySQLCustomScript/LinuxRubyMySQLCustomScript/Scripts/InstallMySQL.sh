#!/bin/bash
sudo apt-get -y update

# set up a silent install of MySQL
dbpass=$1

export DEBIAN_FRONTEND=noninteractive
echo mysql-server-5.5 mysql-server/root_password password $dbpass | debconf-set-selections
echo mysql-server-5.5 mysql-server/root_password_again password $dbpass | debconf-set-selections

# install the LAMP stack
sudo apt-get -y install mysql-server-5.5 ruby ruby-mysql  

