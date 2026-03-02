#!/bin/bash

USERid=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[31m'
G='\e[32m'
Y='\e[33m'
B='\e[34m'

if [ $USERid -ne 0 ]; then
    echo -e "$R Please run this script as root or with sudo. $N" | tee -a $LOGS_FILE
    exit 1
fi
mkdir -p $LOGS_FOLDER

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 installing failed. $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$G $2 installing successfully. $N" | tee -a $LOGS_FILE
    fi
}
cp mongodb.repo /etc/yum.repos.d/mongodb.repo 
VALIDATE $? "Copying Mongo Repo"

dnf install mongodb-org -y 
VALIDATE $? "Installing MongoDB Server"

systemctl enable mongodb 
VALIDATE $? "Enable MongoDB"

systemctl start mongodb 
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections"

systemctl restart mongodb
VALIDATE $? "Restarting MongoDB" 

