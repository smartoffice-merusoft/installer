#! /bin/sh
apt update
apt install wget software-properties-common  curl gpg gnupg2 software-properties-common apt-transport-https lsb-release ca-certificates  postgresql-13 openjdk-8-jdk postgresql-client-common -y

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
timedatectl set-timezone Europe/Moscow
apt-get install chrony -y
systemctl enable chrony
useradd tomcat -U -s /bin/false -d /opt/tomcat -m
wget  https://downloads.apache.org/tomcat/tomcat-9/v9.0.80/bin/apache-tomcat-9.0.80.tar.gz
mkdir /opt/tomcat
tar zxvf apache-tomcat-9.0.80.tar.gz -C /opt/tomcat --strip-components 1
cat > /etc/systemd/system/tomcat.service << EOF

[Unit]
Description=Apache Tomcat Server
After=network.target
[Service]
Type=forking
Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx2048M -server -XX:+UseParallelGC"
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
cp -r ./conf/setenv.sh /opt/tomcat/bin/
cd /opt && sudo chown -R tomcat tomcat/

sed -i -e"s/^#listen_addresses =.*$/listen_addresses = '*'/" /etc/postgresql/13/main/postgresql.conf
echo "host    all    all    0.0.0.0/0    md5" >> /etc/postgresql/13/main/pg_hba.conf
sed -i -e"s/^max_connections = 100.*$/max_connections = 1000/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^shared_buffers =.*$/shared_buffers = 2GB/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#effective_cache_size = 128MB.*$/effective_cache_size = 512MB/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#work_mem = 1MB.*$/work_mem = 16MB/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#maintenance_work_mem = 16MB.*$/maintenance_work_mem = 2GB/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#checkpoint_segments = .*$/checkpoint_segments = 32/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#checkpoint_completion_target = 0.5.*$/checkpoint_completion_target = 0.7/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#wal_buffers =.*$/wal_buffers = 16MB/" /etc/postgresql/13/main/postgresql.conf
sed -i -e"s/^#default_statistics_target = 100.*$/default_statistics_target = 100/" /etc/postgresql/13/main/postgresql.conf

#Поменять пароль для пользователя potgres
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password 'postgres';\""
systemctl restart postgresql

systemctl enable tomcat && systemctl daemon-reload
systemctl start tomcat
