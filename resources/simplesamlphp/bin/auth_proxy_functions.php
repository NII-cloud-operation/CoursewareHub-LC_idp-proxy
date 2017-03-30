<?php
// Common Constants
const ENTITY_DESCRIPTOR = "md:EntityDescriptor";
const ENTITY_ID = "entityID";
const METADATA_PATH = '/var/www/simplesamlphp/metadata/xml/auth-proxies.xml';
const EXIT_OK = 0;
const EXIT_ERROR = 1;
const EXIT_ALREADY_EXIST_ENTITY_ID = 1;


function getEntityDescriptorNode($nodes, $entityID)
{
    $result = null;

    if (!empty($entityID)) {
        for ($i=0; $i<$nodes->length; $i++) {
            $node = $nodes->item($i);
            if ($node->nodeType == XML_ELEMENT_NODE && $node->nodeName == ENTITY_DESCRIPTOR) {
                foreach ($node->attributes as $attr) {
                    if ($attr->localName == ENTITY_ID && $attr->nodeValue == $entityID) {
                        $result = $node;
                        break;
                    }
                }
                if (!is_null($result)) {
                    break;
                }
            }
        }
    }

    return $result;
}

?>
