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

dnf install maven -y &>> $LOGS_FILE
VALIDATE $? "Installed maven"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system shipping" roboshop
    VALIDATE $? "Creating system shipping"
else
    echo -e "$G shipping roboshop already exists $N"
fi
mkdir -p /app &>> $LOGS_FILE
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading shipping"

chown -R roboshop:roboshop /app &>> $LOGS_FILE
VALIDATE $? "Giving Permissions"

cd /app &>> $LOGS_FILE
VALIDATE $? "Moving to app directory"

rm -rf /app/* &>> $LOGS_FILE
VALIDATE $? "Removing existing code"

unzip -o /tmp/shipping.zip &>> $LOGS_FILE
VALIDATE $? "unzip shipping code"

cd /app 
mvn clean package &>> $LOGS_FILE
VALIDATE $? "Installing Building and shipping"

mv target/shipping-1.0.jar shipping.jar &>> $LOGS_FILE
VALIDATE $? "Moving and renaming shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>> $LOGS_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
if [ $? -ne 0 ]; then

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGS_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $LOGS_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> $LOGS_FILE
VALIDATE $? "loaded data into MySQL"
else
    echo -e "data is already loaded ... $Y SKIPPING $N"
fi
systemctl enable shipping 
systemctl start shipping
VALIDATE $? "Enabled and started shipping"



