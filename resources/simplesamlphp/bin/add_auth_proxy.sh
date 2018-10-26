#!/bin/bash

set -eu

auth_proxy_host="$1"

# check parameters
if [ -z "$auth_proxy_host" ] ; then
    reportfailed "too few arguments."
fi
entity_id="https://$auth_proxy_host/simplesaml/module.php"
metadata_url="https://$auth_proxy_host/simplesaml/module.php/saml/sp/metadata.php/default-sp"
tempfile=`mktemp /tmp/xml_XXXXXX`
curl --insecure --fail -o $tempfile $metadata_url
chmod 666 $tempfile
sudo docker cp $tempfile $IDP_PROXY:/root
copyto='/root/'$(basename $tempfile)
sudo docker exec -i $IDP_PROXY bash << EOF
php /var/www/simplesamlphp/bin/add_auth_proxy_metadata.php $entity_id $copyto
EOF
rm -f $tempfile
