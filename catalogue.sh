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
curl -L -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading catalogue"

cd /app
unzip -o /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "Extracting catalogue"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing dependencies"

# Setup service
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying service file"

systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue
VALIDATE $? "Starting catalogue"

# ---------------- MONGODB ----------------

# Create Mongo repo directly (NO external file dependency)
cat <<EOF > /etc/yum.repos.d/mongodb.repo
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=0
enabled=1
EOF

VALIDATE $? "Creating Mongo Repo"

dnf install mongodb-org -y &>> $LOGS_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod
systemctl start mongod
VALIDATE $? "Starting MongoDB"

dnf install mongodb-mongosh -y &>> $LOGS_FILE
VALIDATE $? "Installing Mongo Shell"

INDEX=$(mongosh --host localhost --quiet --eval "db.getMongo().getDB('catalogue').getCollectionNames().indexOf('products')")

if [ -z "$INDEX" ] || [ "$INDEX" -lt 0 ]; then
    mongosh --host localhost </app/db/master-data.js
    VALIDATE $? "Loading catalogue data"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"
