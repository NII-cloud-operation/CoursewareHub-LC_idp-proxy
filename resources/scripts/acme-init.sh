#!/bin/bash

set -e

CERTBOT_OPT=''
CERTBOT_SERVER_OPT=''

if [[ ! -z "${ACME_SERVER}" ]] ; then
    CERTBOT_SERVER_OPT="--server ${ACME_SERVER}"
fi

CERTBOT_OPT=''
if [[ ! -z "${ACME_EAB_KID}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} --eab-kid ${ACME_EAB_KID}"
fi
if [[ ! -z "${ACME_EAB_HMAC_KEY}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} --eab-hmac-key ${ACME_EAB_HMAC_KEY}"
fi
if [[ ! -z "${ACME_EAB_HMAC_ALG}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} --eab-hmac-alg ${ACME_EAB_HMAC_ALG}"
fi
if [[ ! -z "${ACME_EMAIL}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} -m ${ACME_EMAIL}"
fi
if [[ ! -z "${ACME_KEY_TYPE}" ]] ; then
    CERTBOT_OPT="${CERTBOT_OPT} --key-type ${ACME_KEY_TYPE}"
fi

if [[ ! -d /etc/letsencrypt/live/${AUTH_FQDN} ]]; then
    certbot certonly --debug -vvv -n \
        --standalone \
	-d ${AUTH_FQDN} \
        ${CERTBOT_SERVER_OPT} \
        ${CERTBOT_OPT} \
        --agree-tos \
        --no-eff-email
fi

echo "certbot certificates"
certbot ${CERTBOT_SERVER_OPT} certificates || true

ln -s -f /etc/letsencrypt/live/${AUTH_FQDN}/fullchain.pem /etc/pki/nginx/server.cer
ln -s -f /etc/letsencrypt/live/${AUTH_FQDN}/privkey.pem /etc/pki/nginx/private/server.key
ln -s -f /reload-nginx /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
