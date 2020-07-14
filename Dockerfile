FROM docker.io/centos:7

ARG SIMPLESAMLPHP_VERSION="1.18.4"

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
    && yum -y install --enablerepo=epel nginx \
    && systemctl enable nginx \
    && rpm -Uvh /tmp/remi-release-7.rpm \
    && rm /tmp/remi-release-7.rpm \
    #&& yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-remi \
    && yum -y install --enablerepo=remi-php73 composer \
    && yum -y install --enablerepo=remi-php73 php php-fpm php-xml php-gmp php-soap php-ldap \
    && systemctl enable php-fpm \
    # Install simplesamlphp
    && cd /var/www \
    && curl -Lo downloaded-simplesamlphp.tar.gz https://github.com/simplesamlphp/simplesamlphp/releases/download/v${SIMPLESAMLPHP_VERSION}/simplesamlphp-${SIMPLESAMLPHP_VERSION}.tar.gz \
    && tar xvfz downloaded-simplesamlphp.tar.gz \
    && mv $( ls | grep simplesaml | grep -v *tar.gz ) simplesamlphp \
    && rm /var/www/downloaded-simplesamlphp.tar.gz

RUN set -x \
    # Install simplesamlphp-module-attributeaggregator
    && cd /var/www/simplesamlphp \
    && composer config repositories.attributeaggregator '{"type": "vcs", "url": "https://github.com/NII-cloud-operation/simplesamlphp-module-attributeaggregator", "no-api": true}' \
    && composer require niif/simplesamlphp-module-attributeaggregator:dev-2.x-gakunin-cloud-gateway

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
ARG SIMPLESAMLPHP_CONFIG="config.php"
ARG SIMPLESAMLPHP_METAREFRESH_CONFIG="config-metarefresh.php"
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
COPY resources/simplesamlphp/config/${SIMPLESAMLPHP_CONFIG} /var/www/simplesamlphp/config/config.php
COPY resources/simplesamlphp/config/authsources.php /var/www/simplesamlphp/config
COPY resources/simplesamlphp/config/${SIMPLESAMLPHP_METAREFRESH_CONFIG} /var/www/simplesamlphp/config/config-metarefresh.php
COPY resources/simplesamlphp/bin/add_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/remove_auth_proxy_metadata.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/bin/auth_proxy_functions.php /var/www/simplesamlphp/bin
COPY resources/simplesamlphp/metadata/saml20-idp-hosted.php /var/www/simplesamlphp/metadata
COPY resources/simplesamlphp/metadata/xml/auth-proxies.xml /var/www/simplesamlphp/metadata/xml
COPY resources/simplesamlphp/templates/selectidp-dropdown.php /var/www/simplesamlphp/templates/selectidp-dropdown.php
COPY resources/saml/www/sp/discoresp.php /var/www/simplesamlphp/modules/saml/www/sp/discoresp.php
COPY resources/simplesamlphp/bin/add_auth_proxy.sh /usr/local/sbin/
COPY bin/start.sh /start.sh
RUN chmod +x /start.sh \
             /usr/local/sbin/add_auth_proxy.sh

# Setup simplesamlphp config
ARG AUTH_FQDN="nbhub.ecloud.nii.ac.jp"
ARG DS_FQDN="ds.gakunin.nii.ac.jp"
ARG CG_FQDN="cg.gakunin.jp"
RUN sed -i "s;'entityID' => .*;'entityID' => 'https://${AUTH_FQDN}/shibboleth-sp',;" \
    /var/www/simplesamlphp/config/authsources.php
RUN sed -i "s;'entityId' => .*;'entityId' => 'https://${CG_FQDN}/idp/shibboleth',;" \
    /var/www/simplesamlphp/config/config.php
RUN sed -i "s,var embedded_wayf_URL = .*,var embedded_wayf_URL = \"https://${DS_FQDN}/WAYF/embedded-wayf.js\";," \
    /var/www/simplesamlphp/templates/selectidp-dropdown.php
RUN sed -i "s,var wayf_URL = .*,var wayf_URL = \"https://${DS_FQDN}/WAYF\";," \
    /var/www/simplesamlphp/templates/selectidp-dropdown.php
RUN sed -i "s,var wayf_sp_handlerURL = .*,var wayf_sp_handlerURL = \"https://${AUTH_FQDN}/simplesaml/module.php/saml/sp/discoresp.php\";," \
    /var/www/simplesamlphp/templates/selectidp-dropdown.php

VOLUME /etc/cert
ENV CERT_DIR=/etc/cert

# supervisord
COPY resources/supervisord.conf /etc/

CMD /start.sh
