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
                    'validateFingerprint' => '5E:D6:A8:C5:E9:30:49:3F:B4:BA:77:54:6A:FB:66:BA:14:7D:CB:50:5B:EF:0F:D9:7C:26:04:C2:D9:36:FD:81',
                    'validateFingerprintAlgorithm' => 'XMLSecurityDSig::SHA256'
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
                    'src' => 'https://meatwiki.nii.ac.jp/confluence/download/attachments/6684843/cgidp-metadata.xml?api=v2'
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
