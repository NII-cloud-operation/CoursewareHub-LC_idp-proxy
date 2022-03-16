FROM docker.io/centos:7

ARG SIMPLESAMLPHP_VERSION="1.19.5"

# Install packages
ADD http://rpms.famillecollet.com/enterprise/remi-release-7.rpm /tmp/
RUN set -x \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 \
    && yum -y update \
    && yum -y install epel-release \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 \
    && yum -y install less which cronie logrotate supervisor git unzip \
    && systemctl enable crond \
    && yum -y install yum-utils \
    # Install nginx and php
    && yum -y install --enablerepo=epel nginx python3 python3-pip \
    && systemctl enable nginx \
    && rpm -Uvh /tmp/remi-release-7.rpm \
    && rm /tmp/remi-release-7.rpm \
    #&& yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi \
    && yum -y install --enablerepo=remi-php80 php php-fpm php-xml php-gmp php-soap php-ldap \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && systemctl enable php-fpm \
    # Install simplesamlphp
    && cd /var/www \
    && curl -Lo downloaded-simplesamlphp.tar.gz https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}.tar.gz \
    && tar xvfz downloaded-simplesamlphp.tar.gz \
    && mv $( ls | grep simplesaml | grep -v *tar.gz ) simplesamlphp \
    && rm /var/www/downloaded-simplesamlphp.tar.gz \
    && cd /var/www/simplesamlphp \
    && composer require --dev -W \
        "simplesamlphp/simplesamlphp-test-framework:^1.1.5" \
        "phpunit/phpunit:^7.5|^8.5|^9.5" "vimeo/psalm:^4.17" \
    && composer require -W \
        "simplesamlphp/saml2:~4.2.5, <4.2.8" # workaround for "Error: Undefined constant SoapClient::SOAP_1_1"

RUN set -x \
    # Install simplesamlphp-module-attributeaggregator
    && cd /var/www/simplesamlphp \
    && composer config repositories.attributeaggregator '{"type": "vcs", "url": "https://github.com/NII-cloud-operation/simplesamlphp-module-attributeaggregator", "no-api": true}' \
    && composer require --update-no-dev niif/simplesamlphp-module-attributeaggregator:dev-2.x-gakunin-cloud-gateway

# Setup nginx
# Copy the nginx configuration files
COPY resources/nginx/nginx.conf /etc/nginx/
COPY resources/nginx/idp-proxy.conf /etc/nginx/conf.d/
RUN mkdir -p /etc/pki/nginx/private/

# Setup php-fpm
COPY resources/php-fpm/www.conf /etc/php-fpm.d/
RUN chgrp nginx /var/lib/php/session \
    && mkdir -p /run/php-fpm

# Setup simplesamlphp
RUN set -x \
    && mkdir -p /var/www/simplesamlphp/metadata/xml \
    && touch /var/www/simplesamlphp/modules/cron/enable \
    && touch /var/www/simplesamlphp/modules/statistics/disable \
    && touch /var/www/simplesamlphp/modules/metarefresh/enable \
    && cp /var/www/simplesamlphp/modules/cron/config-templates/*.php /var/www/simplesamlphp/config/ \
    && mkdir -p /var/www/simplesamlphp/metadata/gakunin-metadata \
                /var/www/simplesamlphp/metadata/attributeauthority-remote \
                /var/www/simplesamlphp/metadata/open-idp-metadata \
    && chown -R nginx:nginx /var/www/simplesamlphp
COPY resources/simplesamlphp/bin/add_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/remove_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/auth_proxy_functions.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/metadata/saml20-idp-hosted.php /var/www/simplesamlphp/metadata
COPY resources/simplesamlphp/metadata/xml/auth-proxies.xml /var/www/simplesamlphp/metadata/xml
COPY resources/saml/www/sp/discoresp.php /var/www/simplesamlphp/modules/saml/www/sp/discoresp.php
COPY resources/simplesamlphp/bin/add_auth_proxy.sh /usr/local/sbin/
COPY bin/start.sh /start.sh
RUN chmod +x /start.sh \
             /usr/local/sbin/add_auth_proxy.sh

# Install j2li
RUN pip3 install --no-cache-dir j2cli

# Install config template files
COPY resources/etc/templates /etc/templates

VOLUME /etc/cert
ENV CERT_DIR=/etc/cert

# supervisord
COPY resources/supervisord.conf /etc/

CMD /start.sh
