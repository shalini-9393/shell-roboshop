#!/bin/bash

USERid=$(id -u)

LOGS_FOLDER="/var/log/shell-roboshop"
mkdir -p $LOGS_FOLDER
LOGS_FILE="$LOGS_FOLDER/$(basename $0).log"

R='\e[31m'
G='\e[32m'
Y='\e[33m'
B='\e[34m'
N='\e[0m'

if [ $USERid -ne 0 ]; then
    echo -e "$R Please run this script as root or with sudo. $N" | tee -a $LOGS_FILE
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 failed. $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2 successful. $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable redis -y &>> $LOGS_FILE
dnf module enable redis:7 -y 
VALIDATE $? "Enabling Redis :7"

dnf install redis -y &>> $LOGS_FILE
VALIDATE $? "Installed Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>> $LOGS_FILE
VALIDATE $? "Allowing Remote Connections"

systemctl enable redis &>> $LOGS_FILE 
systemctl start redis
VALIDATE $? "Enable and Started Redis"