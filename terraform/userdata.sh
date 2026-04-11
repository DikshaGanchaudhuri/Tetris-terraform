#!/bin/bash
yum update -y
yum install -y nginx git

systemctl start nginx
systemctl enable nginx

cd /usr/share/nginx/html
rm -rf *

git clone https://github.com/jakesgordon/javascript-tetris.git .

# Amazon Linux 2 uses 'nginx' group but files owned by root is fine
chmod -R 755 /usr/share/nginx/html