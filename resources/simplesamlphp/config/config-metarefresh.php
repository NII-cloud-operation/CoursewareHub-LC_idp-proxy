<?php

$config = array(
    'sets' => array(
        'gakunin-metadata' => array(
            'cron' => array('daily'),
            'sources' => array(
                array(
                    'src' => 'https://metadata.gakunin.nii.ac.jp/gakunin-metadata.xml?generation=2',
                    'certificates' => array(
                        'gakunin-signer.cer'
                    ),
                    'validateFingerprint' => '08:A0:D0:B1:A5:52:A4:E6:6F:39:76:BC:E6:69:83:E3:84:E0:02:13',
                )
            ),
            'outputDir' => 'metadata/gakunin-metadata/',
            'outputFormat' => 'flatfile',
            'expireAfter' => 60*60*24*4
        ),
        'attributeauthority-remote' => array(
            'cron' => array('daily'),
            'sources' => array(
                array(
                    'src' => 'https://meatwiki.nii.ac.jp/confluence/download/attachments/6684843/cgidp-metadata.xml?version=2&modificationDate=1488866091000&api=v2',
                )
            ),
            'outputDir' => 'metadata/attributeauthority-remote/',
            'outputFormat' => 'flatfile',
            'expireAfter' => 60*60*24*4
        ),
        'open-idp-metadata' => array(
            'cron' => array('daily'),
            'sources' => array(
                array(
                    'src' => 'https://openidp.nii.ac.jp/idp/shibboleth',
                )
            ),
            'outputDir' => 'metadata/open-idp-metadata/',
            'outputFormat' => 'flatfile',
            'expireAfter' => 60*60*24*4
        )
    )
);
