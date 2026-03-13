#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
USERID=$(id -u)
MYSQL_HOST=172.31.6.76

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

dnf install python3 gcc python3-devel -y &>> $LOGS_FILE
VALIDATE $? "Installed python3 and dependencies"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system payment" roboshop
    VALIDATE $? "Creating system payment"
else
    echo -e "$G payment roboshop already exists $N"
fi
mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading payment"

chown -R roboshop:roboshop /app &>> $LOGS_FILE
VALIDATE $? "Giving Permissions"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/* &>> $LOGS_FILE
VALIDATE $? "Removing existing code"

unzip -o /tmp/payment.zip &>> $LOGS_FILE
VALIDATE $? "unzip payment code"

cd /app 
pip3 install -r requirements.txt &>> $LOGS_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service 
VALIDATE $? "Created systemctl service"

systemctl daemon-reload &>> $LOGS_FILE
systemctl enable payment &>> $LOGS_FILE
systemctl start payment &>> $LOGS_FILE
VALIDATE $? "Enabled and started payment"