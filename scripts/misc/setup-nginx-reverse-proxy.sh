#!/bin/bash

sudo yum install nginx
sudo yum update && sudo yum upgrade -y
sudo /etc/init.d/morpheus-server kill
nginx -v
sudo /etc/init.d/nginx status
sudo /etc/init.d/morpheus-server start
sudo /etc/init.d/morpheus-client start
sudo vim /etc/nginx/nginx.conf

```
server {
   listen         80 default_server;
   listen         [::]:80 default_server;
   server_name    localhost;
   root           /usr/share/nginx/html;
   location / {
       proxy_pass http://127.0.0.1:3000;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host $host;
       proxy_cache_bypass $http_upgrade;
   }
}
```

sudo /etc/init.d/nginx restart

- Ensure nginx restarts if instance is rebooted
sudo chkconfig nginx on
