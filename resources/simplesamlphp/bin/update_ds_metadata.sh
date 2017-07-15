#!/bin/bash

ds_metadata_file="gakunin-metadata.xml"
cg_metadata_file="attributeauthority-remote.xml"
oi_metadata_file="open-idp-metadata.xml"
cd /var/www/simplesamlphp/

sed -i "s|#DS_METADATA_XML#|array('type' => 'xml', 'file' => 'metadata/xml/${ds_metadata_file}')|" config/config.php
sed -i "s|#CG_METADATA_XML#|array('type' => 'xml', 'file' => 'metadata/xml/${cg_metadata_file}')|" config/config.php
sed -i "s|#OI_METADATA_XML#|array('type' => 'xml', 'file' => 'metadata/xml/${oi_metadata_file}')|" config/config.php

/usr/bin/curl -o metadata/xml/${ds_metadata_file} https://metadata.gakunin.nii.ac.jp/${ds_metadata_file}
[ -e "metadata/xml/${cg_metadata_file}" ] || {
/usr/bin/curl -o metadata/xml/${cg_metadata_file} https://meatwiki.nii.ac.jp/confluence/download/attachments/6684843/cgidp-metadata.xml?version=2&modificationDate=1488866091000&api=v2
}
[ -e "metadata/xml/${oi_metadata_file}" ] || {
/usr/bin/curl -o metadata/xml/${oi_metadata_file} https://openidp.nii.ac.jp/idp/shibboleth
}
