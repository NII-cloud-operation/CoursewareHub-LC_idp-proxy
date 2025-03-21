FROM rockylinux:9

ARG SIMPLESAMLPHP_VERSION="2.3.5"
ARG ATTRIBUTE_AGGREGATOR_URL="https://github.com/NII-cloud-operation/simplesamlphp-module-attributeaggregator"
ARG ATTRIBUTE_AGGREGATOR_BRANCH="dev-2.x-gakunin-cloud-gateway"

# Install packages
RUN set -x \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9 \
    && dnf -y update \
    && dnf -y install epel-release \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-9 \
    && dnf -y install less which cronie logrotate supervisor git unzip findutils patch \
    && systemctl enable crond \
    && dnf -y install yum-utils \
    # Install nginx and php
    && dnf -y install --enablerepo=epel nginx python3 python3-pip \
    && systemctl enable nginx \
    && dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi.el9 \
    && dnf -y module reset php \
    && dnf -y module install php:remi-8.3 \
    && dnf -y install --enablerepo=remi php php-fpm php-xml php-gmp php-soap php-ldap \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('sha384', 'composer-setup.php') === '$(curl -q https://composer.github.io/installer.sig)') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && systemctl enable php-fpm \
    # Install simplesamlphp
    && cd /var/www \
    && curl -Lo downloaded-simplesamlphp.tar.gz https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}-full.tar.gz \
    && tar xvfz downloaded-simplesamlphp.tar.gz \
    && mv $( ls | grep simplesaml | grep -v *tar.gz ) simplesamlphp \
    && rm /var/www/downloaded-simplesamlphp.tar.gz \
    # Install simplesamlphp-module-attributeaggregator
    && cd /var/www/simplesamlphp \
    && composer config repositories.attributeaggregator "{\"type\": \"vcs\", \"url\": \"${ATTRIBUTE_AGGREGATOR_URL}\", \"no-api\": true}" \
    && composer require --update-no-dev niif/simplesamlphp-module-attributeaggregator:${ATTRIBUTE_AGGREGATOR_BRANCH}

# Patch simplesamlphp
COPY resources/simplesamlphp/simplesamlphp.patch /tmp/
RUN set -x \
    && cd /var/www/simplesamlphp \
    && patch -p1 < /tmp/simplesamlphp.patch \
    && rm -f /tmp/simplesamlphp.patch

# Setup nginx
# Copy the nginx configuration files
COPY resources/nginx/nginx.conf /etc/nginx/
RUN mkdir -p /etc/pki/nginx/private/

# Setup php-fpm
COPY resources/php-fpm/www.conf /etc/php-fpm.d/
RUN chgrp nginx /var/lib/php/session \
    && mkdir -p /run/php-fpm

# Setup simplesamlphp
RUN set -x \
    && mkdir -p /var/www/simplesamlphp/metadata/xml \
    && mkdir -p /var/www/simplesamlphp/metadata/gakunin-metadata \
                /var/www/simplesamlphp/metadata/attributeauthority-remote \
    && chown -R nginx:nginx /var/www/simplesamlphp
COPY resources/simplesamlphp/bin/add_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/remove_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/auth_proxy_functions.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/metadata/xml/auth-proxies.xml /var/www/simplesamlphp/metadata/xml
COPY resources/simplesamlphp/templates/selectidp-dropdown.twig /var/www/simplesamlphp/templates
COPY resources/simplesamlphp/templates/selectidp-embedded-wayf-start.twig /var/www/simplesamlphp/templates/includes
COPY resources/simplesamlphp/templates/selectidp-embedded-wayf-end.twig /var/www/simplesamlphp/templates/includes
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

CMD ["/start.sh"]
