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

cp mongo.repo /etc/yum.repos.d/mongodb.repo &>> $LOGS_FILE
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB Server"

systemctl enable mongod &>> $LOGS_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>> $LOGS_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGS_FILE
VALIDATE $? "Allowing Remote Connections"

systemctl restart mongod &>> $LOGS_FILE
VALIDATE $? "Restarted MongoDB"



