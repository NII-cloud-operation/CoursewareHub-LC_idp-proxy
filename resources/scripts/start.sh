#!/bin/bash

set -xe

# Setup the keys for nginx
if [[ -e $CERT_DIR/server.cer ]] && [[ -e $CERT_DIR/server.key ]]; then
    ln -s -f $CERT_DIR/server.cer /etc/pki/nginx/server.cer
    ln -s -f $CERT_DIR/server.key /etc/pki/nginx/private/server.key
else
    export ACME_ENABLED=1
    /acme-init.sh
fi

# Setup the keys for simplesamlphp
cp -p $CERT_DIR/idp-proxy.cer /var/www/simplesamlphp/cert/
cp -p $CERT_DIR/idp-proxy.key /var/www/simplesamlphp/cert/
cp -p $CERT_DIR/gakunin-signer.cer /var/www/simplesamlphp/cert/

# Setup config files
TEMPLATE_DIR=/etc/templates

j2 ${TEMPLATE_DIR}/embedded-wayf-config.js.j2 -o /var/www/simplesamlphp/templates/includes/embedded-wayf-config.js
j2 ${TEMPLATE_DIR}/embedded-wayf-loader.js.j2 -o /var/www/simplesamlphp/templates/includes/embedded-wayf-loader.js
j2 ${TEMPLATE_DIR}/idp-proxy.conf.j2 -o /etc/nginx/conf.d/idp-proxy.conf
j2 ${TEMPLATE_DIR}/config.php.j2 -o /var/www/simplesamlphp/config/config.php
j2 ${TEMPLATE_DIR}/authsources.php.j2 -o /var/www/simplesamlphp/config/authsources.php
j2 ${TEMPLATE_DIR}/module_cron.php.j2 -o /var/www/simplesamlphp/config/module_cron.php
j2 ${TEMPLATE_DIR}/cron_root.j2 -o /var/spool/cron/root
j2 ${TEMPLATE_DIR}/saml20-idp-hosted.php.j2 -o /var/www/simplesamlphp/metadata/saml20-idp-hosted.php

if [[ "$ENABLE_TEST_FEDERATION" == "1" || "$ENABLE_TEST_FEDERATION" == "yes" ]]; then
   j2 ${TEMPLATE_DIR}/module_metarefresh-test.php.j2 -o /var/www/simplesamlphp/config/module_metarefresh.php
else
   j2 ${TEMPLATE_DIR}/module_metarefresh.php.j2 -o /var/www/simplesamlphp/config/module_metarefresh.php
fi

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
