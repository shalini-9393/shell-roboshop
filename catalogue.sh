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

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS Module"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS 20 Module"

dnf install nodejs -y &>> $LOGS_FILE 
VALIDATE $? "Installing NodeJS"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOGS_FILE
 VALIDATE $? "Creating system User"
 else
    echo -e "$G User roboshop already exists. $N" | tee -a $LOGS_FILE
fi
mkdir -p /app &>> $LOGS_FILE 
VALIDATE $? "Creating App Directory" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading catalogue code"

unzip -o /tmp/catalogue.zip -d /app &>> $LOGS_FILE
VALIDATE $? "Extracting catalogue code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS dependencies"

chown -R roboshop:roboshop /app &>> $LOGS_FILE
VALIDATE $? "Changing ownership of App Directory"

cp catalogue.service /etc/systemd/system/catalogue.service &>> $LOGS_FILE
VALIDATE $? "Copying catalogue systemd service file"

systemctl daemon-reload &>> $LOGS_FILE
VALIDATE $? "Reloading systemd"

systemctl enable catalogue &>> $LOGS_FILE
VALIDATE $? "Enabling catalogue service"

systemctl start catalogue &>> $LOGS_FILE
VALIDATE $? "Starting catalogue service"