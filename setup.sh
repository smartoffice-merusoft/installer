#! /bin/sh
apt update
apt install wget software-properties-common  curl gpg gnupg2 software-properties-common apt-transport-https lsb-release ca-certificates -y

curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg

echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |tee  /etc/apt/sources.list.d/pgdg.list

apt update

# Specify/replace the version number you want to install
apt install postgresql-13 -y
apt install openjdk-8-jdk -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk
timedatectl set-timezone Europe/Moscow

apt-get install chrony -y

systemctl enable chrony

useradd tomcat -U -s /bin/false -d /opt/tomcat -m

wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.76/bin/apache-tomcat-9.0.76.tar.gz
mkdir /opt/tomcat
tar zxvf apache-tomcat-9.0.76.tar.gz -C /opt/tomcat --strip-components 1
cat > /etc/systemd/system/tomcat.service << EOF

[Unit]
Description=Apache Tomcat Server
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx4096M -server -XX:+UseParallelGC"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

cp -r ./lib/*  /opt/tomcat/lib/
if [ -d /opt/tomcat/conf/Catalina/localhost ]; then echo 'Folder Catalina exists'; else mkdir -p /opt/tomcat/conf/Catalina/localhost ; fi
cp -r ./conf/rewrite.config /opt/tomcat/conf/Catalina/localhost
cp -r ./conf/*.xml /opt/tomcat/conf/

systemctl daemon-reload

systemctl start tomcat
