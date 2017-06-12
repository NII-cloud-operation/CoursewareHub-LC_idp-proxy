#!/usr/bin/env php
<?php
$baseDir = dirname(dirname(__FILE__));
require_once $baseDir.DIRECTORY_SEPARATOR.'bin'.DIRECTORY_SEPARATOR.'auth_proxy_functions.php';

$entityID = $argv[1];
$metadataFilePath = $baseDir.DIRECTORY_SEPARATOR.METADATA_PATH;

$exit_code = EXIT_OK;
try {
    $md = new DOMDocument();
    if (file_exists($metadataFilePath)) {
        $md->load($metadataFilePath);
        $removeNode = getEntityDescriptorNode($md->firstChild->childNodes, $entityID);
        $md->firstChild->removeChild($removeNode);
        $md->save($metadataFilePath);
    }
} catch (Exception $e) {
    echo $e->getMessage()."\n";
    $exit_code = EXIT_ERROR;
}

$md = null;
system("sed -i '/^$/d' $metadataFilePath");

exit($exit_code);
?>
