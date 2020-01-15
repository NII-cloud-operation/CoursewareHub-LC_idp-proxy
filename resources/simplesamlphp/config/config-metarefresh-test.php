<?php

$config = array(
    'sets' => array(
        'gakunin-metadata' => array(
            'cron' => array('daily'),
            'sources' => array(
                array(
                    'src' => 'https://metadata.gakunin.nii.ac.jp/gakunin-test-metadata.xml',
                    'certificates' => array(
                        'gakunin-signer.cer'
                    ),
                    'validateFingerprint' => '36:B6:60:0A:EF:05:A9:BE:B2:E9:79:09:EC:E4:CB:A5:28:D5:DB:71',
                    'validateFingerprintAlgorithm' => 'XMLSecurityDSig::SHA1'
                )
            ),
            'outputDir' => 'metadata/gakunin-metadata/',
            'outputFormat' => 'flatfile',
            'expireAfter' => 60*60*24*4
        )
    )
);
