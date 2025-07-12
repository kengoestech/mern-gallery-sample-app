#!/bin/bash
apt update -y
apt install -y nginx

cat > /etc/nginx/sites-available/default <<EOF
upstream frontend {
    server ${frontend1_private_ip}:3000;
    server ${frontend2_private_ip}:3000;
}

server {
    listen 80;
    location / {
        proxy_pass http://frontend;
    }
}
EOF

systemctl restart nginx