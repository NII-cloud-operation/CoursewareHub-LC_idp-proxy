#!/usr/bin/env php
<?php
$baseDir = dirname(dirname(__FILE__));
require_once $baseDir.DIRECTORY_SEPARATOR.'bin'.DIRECTORY_SEPARATOR.'auth_proxy_functions.php';

$entityID = $argv[1];
$metadataUrl = $argv[2];
$metadataFilePath = $baseDir.DIRECTORY_SEPARATOR.METADATA_PATH;
$addMetadataPath = tempnam("/tmp", "xml");

$exit_code = EXIT_OK;
try {
    system("curl --insecure -o $addMetadataPath $metadataUrl");

    $md = new DOMDocument();
    $md->load($metadataFilePath);

    $existNode = getEntityDescriptorNode($md->firstChild->childNodes, $entityID);
    if (is_null($existNode)) {
        $addMd = new DOMDocument();
        $addMd->load($addMetadataPath);
        $addNode = getEntityDescriptorNode($addMd->childNodes, $entityID);
        $md->documentElement->appendChild($md->importNode($addNode, true));
        $md->documentElement->appendChild($md->createTextNode("\n"));
        $md->save($metadataFilePath);
    } else {
        $exit_code = EXIT_ALREADY_EXIST_ENTITY_ID;
    }
} catch (Exciption $e) {
    echo $e->getMessage()."\n";
    $exit_code = EXIT_ERROR;
}

@unlink($addMetadataPath);
$md = null;
$addMd = null;

exit($exit_code);
?>
