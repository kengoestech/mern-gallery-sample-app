#!/bin/bash
sudo apt update -y
sudo apt install -y nginx

cat > /etc/nginx/sites-available/default <<EOF
upstream frontend {
    server ${frontend1_private_ip}; 
    server ${frontend2_private_ip}; 
}

server {
    listen 80;
    location / {
        proxy_pass http://frontend;
    }
}
EOF

systemctl restart nginx