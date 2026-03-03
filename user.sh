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

# Install NodeJS
dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS"

# Create roboshop user
id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGS_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$G User roboshop already exists $N"
fi

# Create app directory
mkdir -p /app
VALIDATE $? "Creating App Directory"

# Download code
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading user"

cd /app
unzip -o /tmp/user.zip &>> $LOGS_FILE
VALIDATE $? "Extracting user"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable user &>> $LOGS_FILE
systemctl start user
VALIDATE $? "Starting and Enabling user"
