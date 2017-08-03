# IdP-Proxy

## Prerequisite
* Docker version 1.12.5 later
* Be abailable 'sudo'   

## Prepare Server certificate and key
1. Prepare the Server certificate of IdP-Proxy as follow names.
   * idp-proxy.cer
     + Server certificte of IdP-Proxy issued by NII.
   * idp-proxy.chained.cer
     + Authenticated server certificate of IdP-Proxy (Intermediate certificate + Server certificate).
   * idp-proxy.key
     + Private key of IdP-Proxy.
2. Place 'idp-proxy.cer', 'idp-proxy.chained.cer', 'idp-proxy.ey' in arbitrary directory.

## Clone the repository of IdP-Proxy
Make the clone of the repository of IdP-Proxy on GitHub.
```
$ cd GIT_CLONE_DIR
$ git clone git@github.com:axsh/idp-proxy.git
```

## Build image of IdP-Proxy
Build IdP-Proxy container image as 'idp-proxy:latest'.
```
$ cd GIT_CLONE_DIR/idp-proxy
$ ./build-idp-proxy CERT_DIR
```
* Specify the path of the directory where the server certifcates and the private key are placed by 'CERT_DIR'. 

## Run IdP-Proxy
Run IdP-Proxy container using 'idp-proxy:latest' image.
```
$ cd GIT_CLONE_DIR/idp-proxy
$ ./bin/idpproxyctl run
```

## Add Courseware SP to IdP-Proxy
You need to add the Courseware to IdP-Proxy to use the authentication of Gakunin federation.
Add the metadata of Courseware SP into IdP-Proxy.
```
$ cd GIT_CLONE_DIR/idp-proxy
$ ./bin/idpproxyctl add-courseware SP_HOST
```
* Specify the FQDN of the SP of the Courseware by 'SP_HOST'. 
* IdP-Proxy accesses the Courseware SP using the specified FQDN, and gets the SP's metadata.
