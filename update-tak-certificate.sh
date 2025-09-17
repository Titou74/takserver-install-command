#!/bin/sh

# From https://mytecknet.com/lets-sign-our-tak-server/
# Default password is atakatak

## yourdomain.ext --> with point separator --> google.fr
domain=yourdomain.ext
## yourdomain-ext --> with dash separator --> google-fr
fileName=yourdomain-ext

rm -R renew/
mkdir renew

# Create our PKCS12 certificate from our signed certificate and private key
openssl pkcs12 -export -in /etc/letsencrypt/live/$domain/fullchain.pem -inkey /etc/letsencrypt/live/$domain/privkey.pem -out renew/$fileName.p12 -name $domain

# Create our Java Keystore from our PKCS12 certificate
sudo keytool -importkeystore -destkeystore renew/$fileName.jks -srckeystore renew/$fileName.p12 -srcstoretype pkcs12

# Move certificates
mv /opt/tak/certs/letsencrypt/* old-certificates/
mv renew/* /opt/tak/certs/letsencrypt/