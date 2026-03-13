#!/bin/bash

# --------------------------
# Frontend setup for Roboshop
# --------------------------

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
USERID=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
mkdir -p $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$(basename $0).log"

R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script as root or with sudo. $N"
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 failed $N"
        exit 1
    else
        echo -e "$G $2 successful $N"
    fi
}

# --------------------------
# Install and enable Nginx
# --------------------------
dnf module disable nginx -y &>>$LOGS_FILE
dnf module enable nginx:1.24 -y &>>$LOGS_FILE
dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx &>>$LOGS_FILE
VALIDATE $? "Enabled and Started Nginx"

# --------------------------
# Remove default Nginx content
# --------------------------
rm -rf /usr/share/nginx/html/*
VALIDATE $? "Remove default content"

# --------------------------
# Download and unzip frontend
# --------------------------
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloaded frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOGS_FILE
VALIDATE $? "Unzipped frontend"

# --------------------------
# Set up correct nginx.conf
# --------------------------
cat > /etc/nginx/nginx.conf <<EOL
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }
}
EOL

VALIDATE $? "Configured Nginx"

# --------------------------
# Restart Nginx to apply changes
# --------------------------
systemctl restart nginx &>>$LOGS_FILE
VALIDATE $? "Restarted Nginx"