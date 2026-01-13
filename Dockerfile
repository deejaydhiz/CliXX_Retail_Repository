# Use the latest stable version of WordPress/PHP (e.g., 8.3)
FROM wordpress:6.9.0-php8.3-apache
COPY . /var/www/html
RUN apt-get update && apt-get install -y default-mysql-client