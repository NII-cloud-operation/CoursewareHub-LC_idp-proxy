FROM docker.io/centos:7

# Install packages
COPY resources/tmp/remi-release-7.rpm /tmp/
RUN set -x \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
    && yum -y update \
    && yum -y install epel-release \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 \
    && yum -y install less which cronie \
    && systemctl enable crond \
    && yum -y install yum-utils \
    # Install nginx and php
    && yum -y install --enablerepo=epel nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && systemctl enable nginx \
    && rpm -Uvh /tmp/remi-release-7.rpm \ 
    && rm /tmp/remi-release-7.rpm \
    #&& yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi \
    && yum -y install --enablerepo=remi-php56 composer \
    && yum -y install --enablerepo=remi-php56 php php-fpm php-xml php-mcrypt php-gmp php-soap \
    && systemctl enable php-fpm \
    # Install simplesamlphp
    && cd /var/www \
    && curl -Lo downloaded-simplesamlphp.tar.gz https://simplesamlphp.org/download?latest \
    && tar xvfz downloaded-simplesamlphp.tar.gz \
    && mv $( ls | grep simplesaml | grep -v *tar.gz ) simplesamlphp \
    && rm /var/www/downloaded-simplesamlphp.tar.gz 

RUN set -x \
    # Install simplesamlphp-module-attributeaggregator 
    && cat "extension=/opt/remi/php56/root/usr/lib64/php/modules/gmp.so" >> /etc/php.ini \
    && cat "extension=/opt/remi/php56/root/usr/lib64/php/modules/soap.so" >> /etc/php.ini \
    && cd /var/www/simplesamlphp \
    && composer require niif/simplesamlphp-module-attributeaggregator:1.*

# Setup nginx
# Copy the nginx configuration files
COPY resources/nginx/nginx.conf /etc/nginx/
COPY resources/nginx/idp-proxy.conf /etc/nginx/conf.d/
# Setup the keys for nginx
COPY resources/keys/idp-proxy.chained.cer /etc/pki/nginx/
COPY resources/keys/idp-proxy.key /etc/pki/nginx/private/

# Setup php-fpm
COPY resources/php-fpm/www.conf /etc/php-fpm.d/
RUN chgrp nginx /var/lib/php/session

# Setup simplesamlphp
COPY resources/simplesamlphp/config/config.php /var/www/simplesamlphp/config
COPY resources/simplesamlphp/config/authsources.php /var/www/simplesamlphp/config
COPY resources/simplesamlphp/bin/update_ds_metadata.sh /var/www/simplesamlphp/bin
RUN set -x \
    && mkdir -p /var/www/simplesamlphp/metadata/xml \
    && chown -R nginx:nginx /var/www/simplesamlphp
     
# Setup the keys for simplesamlphp
COPY resources/keys/idp-proxy.cer /var/www/simplesamlphp/cert/
COPY resources/keys/idp-proxy.key /var/www/simplesamlphp/cert/

# Set cron for Gakunin metadata updating
RUN set -x \
    && echo "0 0 */10 * * /var/www/simplesamlphp/bin/update_ds_metadata.sh" > /var/spool/cron/root

# Boot up Nginx, and PHP5-FPM when container is started
CMD systemctl php5.6-fpm start && systemctl nginx start

