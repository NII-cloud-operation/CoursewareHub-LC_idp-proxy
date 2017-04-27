#!/bin/bash

metadata_file=gakunin-test-metadata.xml
cd /var/www/simplesamlphp/
/usr/bin/curl -o metadata/xml/${metadata_file} https://metadata.gakunin.nii.ac.jp/${metadata_file}
sed -i "s|#DS_METADATA_XML#|array('type' => 'xml', 'file' => 'metadata/xml/${metadata_file}')|" config
/config.php
