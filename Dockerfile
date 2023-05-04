# Use Fedora as the base image
FROM fedora:latest

# Update packages and install necessary dependencies
RUN dnf -y update && \
    dnf -y install git cronie nginx php php-fpm php-cli php-common php-gd php-mbstring php-mysqlnd php-xml php-json

# Clone bashupload repository
RUN git clone https://github.com/IO-Technologies/bashupload.git /var/www/bashupload

# Create /var/files directory and set permissions
RUN mkdir -p /var/files && \
    chown -R nginx:nginx /var/files && \
    chmod -R 755 /var/files

# Set permissions for the web directory
RUN chown -R nginx:nginx /var/www/bashupload && \
    chmod -R 755 /var/www/bashupload

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/php-fpm.d/www.conf
# COPY config.local.php /var/www/bashupload/config.local.php
RUN rm -rf /var/www/bashupload/config.local.php

ENV PHP_MEMORY_LIMIT=2048M \
    PHP_MAX_UPLOAD=512G \
    PHP_MAX_POST=512G

# Create the crontab file with the cron job entry
RUN echo "0 * * * * php /var/www/bashupload/tasks/clean.php" > /etc/cron.d/clean-cron

# Set proper permissions for the cron file and start the cron service
RUN chmod 0644 /etc/cron.d/clean-cron
RUN crontab /etc/cron.d/clean-cron
RUN touch /var/log/cron.log

# Create /run/php-fpm directory
RUN mkdir -p /run/php-fpm

VOLUME /var/files

# Expose ports 80 and 443
EXPOSE 80 443

# Start nginx and php-fpm
CMD ["sh", "-c", "nginx && php-fpm -F"]
