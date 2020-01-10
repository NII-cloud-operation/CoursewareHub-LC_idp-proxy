<?php

/**
 * Handler for response from IdP discovery service.
 */

\SimpleSAML\Logger::debug('discoresp.php: _REQUEST: '.var_export($_REQUEST,true));

if (!array_key_exists('AuthID', $_REQUEST) && array_key_exists('target', $_REQUEST)) {
    $target_query = parse_url($_REQUEST['target'], PHP_URL_QUERY);
    \SimpleSAML\Logger::debug('discoresp.php: target_query: '.$target_query);
    parse_str($target_query, $req);
} else {
    $req = $_REQUEST;
}

if (array_key_exists('entityID', $_REQUEST)) {
    $req['idpentityid'] = $_REQUEST['entityID'];
}

if (!array_key_exists('AuthID', $req)) {
    throw new \SimpleSAML\Error\BadRequest('Missing AuthID to discovery service response handler');
}

if (!array_key_exists('idpentityid', $req)) {
    throw new \SimpleSAML\Error\BadRequest('Missing idpentityid to discovery service response handler');
}

/** @var array $state */
$state = \SimpleSAML\Auth\State::loadState($req['AuthID'], 'saml:sp:sso');

// Find authentication source
assert(array_key_exists('saml:sp:AuthId', $state));
$sourceId = $state['saml:sp:AuthId'];

$source = \SimpleSAML\Auth\Source::getById($sourceId);
if ($source === null) {
    throw new Exception('Could not find authentication source with id ' . $sourceId);
}
if (!($source instanceof \SimpleSAML\Module\saml\Auth\Source\SP)) {
    throw new \SimpleSAML\Error\Exception('Source type changed?');
}

$source->startSSO($req['idpentityid'], $state);
