#!/bin/bash

OPT=$1

BASE_DIR=$(cd $(dirname $0);cd ../../;pwd)

mkdir -p $BASE_DIR/image-build/idp-proxy/resources/tmp
(cd $BASE_DIR/image-build/idp-proxy/resources/tmp; curl -O http://rpms.famillecollet.com/enterprise/remi-release-7.rpm)
mkdir -p $BASE_DIR/image-build/idp-proxy/resources/keys
cp -p ~/cert/idp-proxy/nbhub.ecloud.nii.ac.jp.chained.cer $BASE_DIR/image-build/idp-proxy/resources/keys/idp-proxy.chained.cer
cp -p ~/cert/idp-proxy/nbhub.ecloud.nii.ac.jp.cer $BASE_DIR/image-build/idp-proxy/resources/keys/idp-proxy.cer
cp -p ~/cert/idp-proxy/nbhub.ecloud.nii.ac.jp.key $BASE_DIR/image-build/idp-proxy/resources/keys/idp-proxy.key

sudo docker build $OPT -t idp-proxy:latest ./

