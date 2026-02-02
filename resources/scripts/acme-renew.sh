#!/bin/bash

set -e

CERTBOT_OPT=''
if [[ ! -z "${ACME_KEY_TYPE}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} --key-type ${ACME_KEY_TYPE}"
fi

if [[ -d /etc/letsencrypt/live/${AUTH_FQDN} ]]; then
    /usr/local/bin/certbot renew ${CERTBOT_OPT}  --webroot -w /var/www "$@"
fi

