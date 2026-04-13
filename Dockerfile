FROM rockylinux/rockylinux:9

ARG SIMPLESAMLPHP_VERSION="2.4.4"
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
    && dnf -y install --enablerepo=epel nginx python3.12 python3.12-pip \
    && systemctl enable nginx \
    && dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi.el9 \
    && dnf -y module reset php \
    && dnf -y module install php:remi-8.4 \
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
COPY --chmod=755 resources/simplesamlphp/bin/add_auth_proxy.sh /usr/local/sbin/
COPY --chmod=755 resources/scripts/start.sh /start.sh

# Install jinja2-cli
RUN pip3.12 install --no-cache-dir jinja2-cli

# Install certbot
RUN pip3.12 install --no-cache-dir certbot
COPY --chmod=755 resources/scripts/acme-init.sh /acme-init.sh
COPY --chmod=755 resources/scripts/acme-renew.sh /acme-renew.sh
COPY --chmod=755 resources/scripts/reload-nginx /reload-nginx

# Install config template files
COPY resources/etc/templates /etc/templates

# Metadata signing cerfiticates
VOLUME /etc/cert
ENV CERT_DIR=/etc/cert \
    SSP_CERT_DIR=/var/www/simplesamlphp/cert \
    GAKUNIN_SIGNER_FILENAME=gakunin-signer.cer \
    GAKUNIN_SIGNER_SHA256=5E:D6:A8:C5:E9:30:49:3F:B4:BA:77:54:6A:FB:66:BA:14:7D:CB:50:5B:EF:0F:D9:7C:26:04:C2:D9:36:FD:81 \
    GAKUNINTEST_SIGNER_FILENAME=gakunintest-signer.cer \
    GAKUNINTEST_SIGNER_SHA256=FA:11:11:5B:EC:13:4D:55:85:AF:60:32:E1:6C:01:01:EF:9C:A0:6B:17:8C:8B:9C:7F:2B:69:41:EB:68:30:1E \
    ORTHROS_SIGNER_FILENAME=orhtoros-signer.cer \
    ORTHROS_SIGNER_SHA256=C7:AE:69:98:AC:E7:6A:C2:83:CC:5F:99:0A:C1:3C:A1:62:3D:F6:84:AA:7B:08:30:37:2D:DA:6B:82:AB:BA:44 \
    ORTHROSSTG_SIGNER_FILENAME=orthrosstg-signer.cer \
    ORTHROSSTG_SIGNER_SHA256=A3:AF:64:82:1B:BF:C9:28:E9:E7:0D:5E:7C:04:41:1C:2D:87:47:1F:45:1D:24:32:B6:31:FF:91:B5:71:53:0D
RUN curl -q -L -o ${SSP_CERT_DIR}/${GAKUNIN_SIGNER_FILENAME} https://metadata.gakunin.nii.ac.jp/gakunin-signer-2017.cer && \
    curl -q -L -o ${SSP_CERT_DIR}/${GAKUNINTEST_SIGNER_FILENAME} https://metadata.gakunin.nii.ac.jp/gakunin-test-signer-2020.cer && \
    curl -q -L -o ${SSP_CERT_DIR}/${ORTHROS_SIGNER_FILENAME} https://core.orthros.gakunin.nii.ac.jp/metadata/orthros-signer-2025.cer && \
    curl -q -L -o ${SSP_CERT_DIR}/${ORTHROSSTG_SIGNER_FILENAME} https://core-stg.orthros.gakunin.nii.ac.jp/metadata/orthrosstg-signer-2025.cer && \
    test "${GAKUNIN_SIGNER_SHA256}" = \
         "$(openssl x509 -fingerprint -sha256 -noout -in ${SSP_CERT_DIR}/${GAKUNIN_SIGNER_FILENAME} | awk -F = '{print $2}')" && \
    test "${GAKUNINTEST_SIGNER_SHA256}" = \
         "$(openssl x509 -fingerprint -sha256 -noout -in ${SSP_CERT_DIR}/${GAKUNINTEST_SIGNER_FILENAME} | awk -F = '{print $2}')" && \
    test "${ORTHROS_SIGNER_SHA256}" = \
         "$(openssl x509 -fingerprint -sha256 -noout -in ${SSP_CERT_DIR}/${ORTHROS_SIGNER_FILENAME} | awk -F = '{print $2}')" && \
    test "${ORTHROSSTG_SIGNER_SHA256}" = \
         "$(openssl x509 -fingerprint -sha256 -noout -in ${SSP_CERT_DIR}/${ORTHROSSTG_SIGNER_FILENAME} | awk -F = '{print $2}')"

# supervisord
COPY resources/supervisord.conf /etc/

CMD ["/start.sh"]
