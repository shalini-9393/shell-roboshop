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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Added RabbitMQ repo file"

dnf install rabbitmq-server -y &>> $LOGS_FILE
VALIDATE $? "Installed RabbitMQ Server"

systemctl enable rabbitmq-server &>> $LOGS_FILE
systemctl start rabbitmq-server
VALIDATE $? "Enable and Started RabbitMQ Server"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Created User and Given Permissions"
