function add_website () {
  if [ $# -eq 0 ]
  then
  echo ""
  echo "###############################################"
  echo "#    Example > add_website tristan.com      #"
  echo "###############################################"
  echo -n "Enter Website Domain: "
  read input_domain_name
  domain_name=$(echo "$input_domain_name" | tr '[:upper:]' '[:lower:]')
  else
  domain_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  fi
  sudo mkdir -p /var/www/$domain_name/html
  sudo chown -R $USER:$USER /var/www/$domain_name/html
  sudo chmod -R 755 /var/www/$domain_name
  echo "<h1> Welcome to $domain_name </h1>" > /var/www/$domain_name/html/index.html

  echo -n "Setup DYN DNS? (y/n): "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo -n "Google DYNDNS Username: "
    read dns_username
    echo -n "Google DYNDNS Password: "
    read dns_password
    sudo tee -a /etc/ddclient.conf <<EOL >/dev/null
login=$dns_username
password=$dns_password
$domain_name
EOL
    sudo service ddclient stop
    sudo rm /var/cache/ddclient/ddclient.cache
    sudo service ddclient start
    sudo systemd-resolve --flush-caches
    echo "Updating DYDNS..."
    sleep 5s
  fi

  echo -n "Have you setup up A record and CNAME on Google Domains? (y/n): "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
    external_ip=`dig @resolver1.opendns.com A myip.opendns.com +short -4`
    checkarecord=`dig $domain_name +short`
    echo "A Record set to:                      "$checkarecord
    if [[ "$checkarecord" == "$external_ip" ]]; then
      echo "                                        ✅ A Record Set Correctly"
    else
      echo "                                        ⛔️ A Record INCORRECT"
      return
    fi
    echo ""
    cname=`dig cname www.$domain_name +short`
    echo "CNAME for www set to:                 "$cname
    if [[ "$cname" == "$domain_name." ]]; then
      echo "                                        ✅ CNAME Set Correctly"
    else
      echo "                                        ⛔️ CNAME INCORRECT"
      return
    fi
  else
    return
  fi

  echo -n "Setting up SSL..."
  sudo certbot certonly --nginx -d $domain_name -d www.$domain_name
  echo -n "Setting up NGINX..."
  sudo tee -a /etc/nginx/sites-available/$domain_name <<EOL >/dev/null
server {
  root /var/www/$domain_name/html;
  index index.html index.htm index.nginx-debian.html;

  server_name $domain_name www.$domain_name;

  if (\$host = www.$domain_name) {
  return 301 https://$domain_name\$request_uri;
  }

  location / {
  try_files \$uri \$uri/ =404;
  }

  listen [::]:443 ssl;
  listen 443 ssl;
  ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;
  include /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
  if (\$host = www.$domain_name) {
  return 301 https://$domain_name\$request_uri;
  }
  if (\$host = $domain_name) {
  return 301 https://\$host\$request_uri;
  }

  listen 80;
  listen [::]:80;
  server_name $domain_name www.$domain_name;
  return 404;
}
EOL

  sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/
  sudo nginx -t

  echo -n "Restart NGINX? (y/n): "
  read answer
  if [ "$answer" != "${answer#[Yy]}" ] ;then
  sudo systemctl restart nginx
  else
  return
  fi

}
