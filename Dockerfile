FROM richarvey/nginx-php-fpm:latest
MAINTAINER dklee@yidigun.com

RUN mv /var/www/html/index.php /var/www/html/phpinfo.php
COPY index.php /var/www/html/
COPY fastcgi.conf /etc/nginx/
