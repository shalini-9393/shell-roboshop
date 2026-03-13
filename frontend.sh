#!/bin/bash

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

dnf module disable nginx -y &>>LOGS_FILE
dnf module enable nginx:1.24 -y&>>LOGS_FILE
dnf install nginx -y&>>LOGS_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>LOGS_FILE
systemctl start nginx 
VALIDATE $? "Enabled and Started nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Remove default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>LOGS_FILE
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>LOGS_FILE
VALIDATE $? "Downloaded and unzipped frontend"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied our niginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarted nginx"