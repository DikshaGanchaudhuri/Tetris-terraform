#!/bin/bash
yum update -y
yum install -y nginx git

systemctl start nginx
systemctl enable nginx

cd /usr/share/nginx/html
rm -rf *

git clone https://github.com/jakesgordon/javascript-tetris.git .

chown -R nginx:nginx /usr/share/nginx/html