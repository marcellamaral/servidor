#!/bin/bash
######################################################
# Basic settings
######################################################

# server base directory
RAGNAROK_DIR=/servidor

# mysql database settings
MYSQL_ROOT_PW="15869856Ma."
MYSQL_RAGNAROK_DB="ragnarok"
MYSQL_RAGNAROK_USER="rathena21"
MYSQL_RAGNAROK_PW="15869856Ma."

# Official server name
SERVER_NAME="DoideRO"
# Client version used by players
SERVER_CLIENT_VERSION="20180621"
# Servers public (WAN) IP
SERVER_PUBLIC_IP="212.1.214.46"
# Servers MOTD
SERVER_MOTD="Bem-Vindo ao DoideRO"

# Server game master account
SERVER_GM_USER="Yamazuki"
SERVER_GM_PW="15869856Ma."

######################################################
# Update System
######################################################

apt-get update -y && apt-get upgrade -y

# install needed packages
apt-get install -y git make libmysqlclient-dev zlib1g-dev libpcre3-dev
apt-get update -y
apt-get install -y gcc-5

sleep 10

apt-get install -y g++-5

sleep 10

ln -s /usr/bin/gcc-5 /usr/bin/gcc
ln -s /usr/bin/g++-5 /usr/bin/g++

#######################################################
# download ragnarok packages
#######################################################

mkdir -p /servidor
git clone https://github.com/rathena/rathena.git $RAGNAROK_DIR

# compile binaries
cd $RAGNAROK_DIR
git pull

./configure
make server
chmod a+x login-server && chmod a+x char-server && chmod a+x map-server

########################################################
# install mysql
########################################################

# Install packages
apt-get install -y mysql-server mysql-client

# cleanup default mysql installation
echo "Cleaning up mysql installation..."
mysql -e "UPDATE mysql.user SET Password = PASSWORD('$MYSQL_ROOT_PW') WHERE User = 'root'"
mysql -e "DROP USER ''@'localhost'"
mysql -e "DROP USER ''@'$(hostname)'"
mysql -e "DROP DATABASE test"
mysql -e "FLUSH PRIVILEGES"
echo "Done!"
echo ""

# Create default ragnarok user and database
echo "Creating Database ${MYSQL_RAGNAROK_DB}..."
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE DATABASE ${MYSQL_RAGNAROK_DB} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE DATABASE logging /*\!40100 DEFAULT CHARACTER SET utf8 */;"
echo "Database successfully created!"
echo "Showing existing databases..."
mysql -uroot -p${MYSQL_ROOT_PW} -e "show databases;"
echo ""
mysql -uroot -p${MYSQL_ROOT_PW} -e "CREATE USER ${MYSQL_RAGNAROK_USER}@localhost IDENTIFIED BY '${MYSQL_RAGNAROK_PW}';"
echo "User successfully created!"
echo ""
echo "Granting ALL privileges on ${MYSQL_RAGNAROK_DB} to ${MYSQL_RAGNAROK_USER}!"
mysql -uroot -p${MYSQL_ROOT_PW} -e "GRANT ALL PRIVILEGES ON ${MYSQL_RAGNAROK_DB}.* TO '${MYSQL_RAGNAROK_USER}'@'localhost';"
mysql -uroot -p${MYSQL_ROOT_PW} -e "GRANT ALL PRIVILEGES ON logging.* TO '${MYSQL_RAGNAROK_USER}'@'localhost';"
mysql -uroot -p${MYSQL_ROOT_PW} -e "FLUSH PRIVILEGES;"
echo "Done!"

# import rathena sql files
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} ${MYSQL_RAGNAROK_DB} < ${RAGNAROK_DIR}/sql-files/main.sql
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} logging < ${RAGNAROK_DIR}/sql-files/logs.sql

# create admin account
mysql -u ${MYSQL_RAGNAROK_USER} -p${MYSQL_RAGNAROK_PW} -D${MYSQL_RAGNAROK_DB} -e "INSERT INTO login (account_id, userid, user_pass, sex, email, group_id, state, unban_time, expiration_time, logincount, lastlogin, last_ip, birthdate, character_slots, pincode, pincode_change, vip_time, old_group) VALUES ('2000001', '${SERVER_GM_USER}', '${SERVER_GM_PW}', 'M', 'a@a', '99', '0', '0', '0', '0', NULL, '', NULL, '0', '', '0', '0', '0');"

########################################################
# configure rathena config files
########################################################

# Configure motd
cat << EOF > ${RAGNAROK_DIR}/conf/motd.text
${SERVER_MOTD}
EOF

# recompile the server binaries
./configure --enable-epoll=yes --enable-prere=yes --enable-vip=no --enable-packetver=${SERVER_CLIENT_VERSION}
make clean
make server

########################################################
# install apache2
########################################################q

apt-get install -y apache2
apt-get install -y php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-gd php7.0-opcache
apt-get install -y phpmyadmin

echo "Include /etc/phpmyadmin/apache.conf" >> /etc/apache2/apache2.conf
service apache2 restart
