#account provisioning and generation of public khakis
function account_provision {
    useradd -U $username
    usermod -G webroot $username
    userpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    echo $userpass | passwd --stdin $username
    mkdir /home/$username/.ssh
    touch /home/$username/.ssh/authorized_keys
    echo $publickey >> /home/$username/.ssh/authorized_keys
    chown $username:$username /home/$username/.ssh -R
    chmod 700 /home/$username/.ssh -R
}
#webspace provisioning
function webspace_provision {
    mkdir -p /srv/www/$domainname/logs /srv/www/$domainname/public_html
    touch /srv/www/$domainname/logs/access.log /srv/www/$domainname/logs/error.log 
    chmod 750 /srv/www/$domainname -R | chown $username:webroot /srv/www/$domainname -R
}
#create database for user
function database_provision {
    clientdbpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
    mysql -u$dbuname -p$dbpword -e "CREATE DATABASE "$username"_db"
    mysql -u$dbuname -p$dbpword -e "GRANT ALL PRIVILEGES ON "$username"_db.* TO "$username"@localhost IDENTIFIED BY '$clientdbpass'"
}
#adding domain config for vhosts

function vhost_provision {
    vhostfile="server {
    listen 80;
    server_name $servername;
    add_header X-Frame-Options \"SAMEORIGIN\";
    access_log /srv/www/$domainname/logs/access.log;
    error_log /srv/www/$domainname/logs/error.log;
    root /srv/www/$domainname/public_html;

    location / {
        index index.html index.htm index.php;
    }

    location ~ \\.php$ {
        try_files \$uri =404;
        include /etc/nginx/fastcgi_params;
        fastcgi_pass  127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /srv/www/$domainname/public_html\$fastcgi_script_name;
    }
}"
    touch /etc/nginx/sites-available/$domainname
    echo "$vhostfile" >> /etc/nginx/sites-available/$domainname
    ln -s /etc/nginx/sites-available/$domainname /etc/nginx/sites-enabled/$domainname
    /etc/init.d/nginx restart
    /etc/init.d/php-fpm restart
}

#generate logs
function user_logs {
    touch ~/useraccounts/$username
    echo "$domainname" >> ~/useraccounts/$username
    echo "$clientdbpass" >> ~/useraccounts/$username
    date +%Y-%m-%d" "%H:%M:%S >> ~/useraccounts/$username
}

