#!/bin/bash

set -xe

# Setup the keys for nginx
cp -p $CERT_DIR/idp-proxy.chained.cer /etc/pki/nginx/
cp -p $CERT_DIR/idp-proxy.key /etc/pki/nginx/private/

# Setup the keys for simplesamlphp
cp -p $CERT_DIR/idp-proxy.cer /var/www/simplesamlphp/cert/
cp -p $CERT_DIR/idp-proxy.key /var/www/simplesamlphp/cert/
cp -p $CERT_DIR/gakunin-signer.cer /var/www/simplesamlphp/cert/

# Setup config files
TEMPLATE_DIR=/etc/templates

j2 ${TEMPLATE_DIR}/config.php.j2 -o /var/www/simplesamlphp/config/config.php
j2 ${TEMPLATE_DIR}/selectidp-dropdown.php.j2 -o /var/www/simplesamlphp/templates/selectidp-dropdown.php
j2 ${TEMPLATE_DIR}/authsources.php.j2 -o /var/www/simplesamlphp/config/authsources.php
j2 ${TEMPLATE_DIR}/module_cron.php.j2 -o /var/www/simplesamlphp/config/module_cron.php
j2 ${TEMPLATE_DIR}/cron_root.j2 -o /var/spool/cron/root

touch /var/www/simplesamlphp/modules/metarefresh/enable
if [[ "$ENABLE_TEST_FEDERATION" == "1" || "$ENABLE_TEST_FEDERATION" == "yes" ]]; then
   j2 ${TEMPLATE_DIR}/config-metarefresh-test.php.j2 -o /var/www/simplesamlphp/config/config-metarefresh-test.php
else
   j2 ${TEMPLATE_DIR}/config-metarefresh.php.j2 -o /var/www/simplesamlphp/config/config-metarefresh.php
fi

/usr/bin/supervisord -n -c /etc/supervisord.conf
