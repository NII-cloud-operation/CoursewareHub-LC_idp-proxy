<?php

/**
 * Handler for response from IdP discovery service.
 */

if (!array_key_exists('AuthID', $_REQUEST) && array_key_exists('target', $_REQUEST)) {
    $target_query = parse_url($_REQUEST['target'], PHP_URL_QUERY);
    error_log($target_query);
    parse_str($target_query, $req);
} else {
    $req = $_REQUEST;
}
$req['idpentityid'] = $_REQUEST['entityID'];

if (!array_key_exists('AuthID', $req)) {
	throw new SimpleSAML_Error_BadRequest('Missing AuthID to discovery service response handler');
}

if (!array_key_exists('idpentityid', $req)) {
	throw new SimpleSAML_Error_BadRequest('Missing idpentityid to discovery service response handler');
}
$state = SimpleSAML_Auth_State::loadState($req['AuthID'], 'saml:sp:sso');

// Find authentication source
assert('array_key_exists("saml:sp:AuthId", $state)');
$sourceId = $state['saml:sp:AuthId'];

$source = SimpleSAML_Auth_Source::getById($sourceId);
if ($source === NULL) {
	throw new Exception('Could not find authentication source with id ' . $sourceId);
}
if (!($source instanceof sspmod_saml_Auth_Source_SP)) {
	throw new SimpleSAML_Error_Exception('Source type changed?');
}

$source->startSSO($req['idpentityid'], $state);
