# **Takserver Install Commands**
Simple readme to explain how to install a takserver on a Ubuntu server

## Good to know
All command bellow were tested on september 2025 on an Ubuntu 22.04 LTS server with TakServer 5.5 release 53.
Commands may not work on future versions.

## Requirements
- A server with Ubuntu 22.04 LTS
- A .deb file from tak.gov - version CORE "UBUNTU" (file mane look like "takserver_5.5-RELEASE53_all.deb")
- A domain pointing your server

## Install TAK Server
### Add Postgresql repository (required for takserver)
Create required folder
```
sudo mkdir -p /etc/apt/keyrings
```

Add postgresql repository
```
sudo curl https://www.postgresql.org/media/keys/ACCC4CF8.asc --output /etc/apt/keyrings/postgresql.asc
```
```
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list'
```

### Update the systeme
```
sudo apt update
```
```
sudo apt upgrade
```

If reboot is necessary after some upgrade
```
sudo reboot
```

### Install takserver
Upload your .deb file on /tmp folder

Install takserver from /tmp
```
cd /tmp
```
```
sudo apt install takserver_5.5-RELEASE53_all.deb
```

Update daemon
```
sudo systemctl daemon-reload
```

Start takserver
```
sudo systemctl start takserver
```

Enable takserver to automatic start on system startup
```
sudo systemctl enable takserver
```

## Generate SSL certificate with Let's Encrypt
### Install Let's Encrypt
Install snap
```
sudo apt install snap
```
Install cerbot with snap
```
sudo snap install --classic certbot
```
### Generate certificate for your domain
```
sudo certbot certonly --standalone
```
SSL files is located on /etc/letsencrypt/live/<yourdomain.ext>/

## Install certificate on takserver
### Set domain variable
You have to set some variables for the next commands. You have to setup the domain pointing your server
```
export domain=<yourdomain.ext>
```
This variable have to be the same of you domain, but you have to replace the dot "." by a dash "-"
```
export fileName=<yourdomain-ext>
```

### Create required folders
```
mkdir /opt/tak/certs/letsencrypt
```
```
mkdir /opt/tak/certs/letsencrypt/renew
```
### Generate certificate files
```
cd /opt/tak/certs/letsencrypt
```

Generate p12 files. If password is asked, type "atakatak"
```
openssl pkcs12 -export -in /etc/letsencrypt/live/$domain/fullchain.pem -inkey /etc/letsencrypt/live/$domain/privkey.pem -out renew/$fileName.p12 -name $domain
```
Import keystore
```
sudo keytool -importkeystore -destkeystore $fileName.jks -srckeystore renew/$fileName.p12 -srcstoretype pkcs12
```
## Configure server certificates
Go to certs directory
```
cd /opt/tak/certs
```
Set some variables
```
export STATE=state
```
```
export CITY=city
```
```
export ORGANIZATIONAL_UNIT=org_unit
```
Generate certificates
```
./makeRootCa.sh --ca-name takserver-CA
```
If asked if move file, answer YES
```
./makeCert.sh ca intermediate-CA
```
```
./makeCert.sh server takserver
```
Restart takserver
```
sudo service takserver restart
```
### File modification
#### Replace

Replace this line
```
<connector port="8446" clientAuth="false" _name="cert_https"/>
```
With (take care: you have to set the domain name with dot replaced by dash)
```
<connector port="8446" clientAuth="false" _name="cert_https" truststorePass="atakatak" truststoreFile="certs/files/truststore-intermediate-CA.jks" truststore="JKS" keystorePass="atakatak" keystoreFile="certs/letsencrypt/<yourdomain-ext>.jks" keystore="JKS"/>
```
---
Replace this line
```
<auth>
```
With this line
```
<auth x509groups="true" x509addAnonymous="false" x509useGroupCache="true" x509checkRevocation="true">
```
---
Replace this line
```
<tls keystore="JKS" keystoreFile="certs/files/takserver.jks" keystorePass="atakatak" truststore="JKS" truststoreFile="certs/files/truststore-root.jks" truststorePass="atakatak" context="TLSv1.2" keymanager="SunX509"/>
```
With this line
```
<tls keystore="JKS" keystoreFile="certs/files/takserver.jks" keystorePass="atakatak" truststore="JKS" truststoreFile="certs/files/truststore-intermediate-CA.jks" truststorePass="atakatak" context="TLSv1.2" keymanager="SunX509"/>
```
#### Remove

Remove if exist
```
<input auth="anonymous" _name="stdtcp" protocol="tcp" port="8087"/>
<input auth="anonymous" _name="stdudp" protocol="udp" port="8087"/>
<input auth="anonymous" _name="streamtcp" protocol="stcp" port="8088"/>
<connector port="8080" tls="false" _name="http_plaintext"/>
```
#### Add

Add after
```
<input _name="stdssl 8089" protocol="tls" port="8089" coreVersion="2"/>
```
This line. It define that you can connect to takserver with the port 8089 from your tak client
```
<input _name="cassl" auth="x509" protocol="tls" port="8089" />
```
If you want more port, you can add more
```
<input _name="cassl 18089" auth="x509" protocol="tls" port="18089" />
<input _name="cassl 38089" auth="x509" protocol="tls" port="38089" />
<input _name="cassl 58089" auth="x509" protocol="tls" port="58089" />
```
---
Add after
```
<dissemination smartRetry="false"/>
```
This lines
```
<certificateSigning CA="TAKServer">
    <certificateConfig>
         <nameEntries>
             <nameEntry name="O" value="TAK"/>
             <nameEntry name="OU" value="TAK"/>
         </nameEntries>
    </certificateConfig>
    <TAKServerCAConfig keystore="JKS" keystoreFile="/opt/tak/certs/files/intermediate-CA-signing.jks" keystorePass="atakatak" validityDays="30" signatureAlg="SHA256WithRSA"/>
</certificateSigning>
```

Save file
Exit file

Restart server
```
sudo systemctl restart takserver
```

Access to your domain on port 8446 : https://yourdomain.ext:8446/
It should work. If not, you probably make a mistake on CoreConfig update

## Configure admin account
```
cd /opt/tak/certs
```
Set some variables
```
export STATE=state
```
```
export CITY=city
```
```
export ORGANIZATIONAL_UNIT=org_unit
```
Create certificate for admin user
```
./makeCert.sh client <admin-login>
```
Create admin user. The password require some complexity: ```minimum of 15 characters including 1 uppercase, 1 lowercase, 1 number, and 1 special character from this list [-_!@#$%^&*(){}[]+=~`|:;<>,./?]```
```
java -jar /opt/tak/utils/UserManager.jar usermod -A -p '<admin-password>' <admin-login>
```
### Configure takserver to use the certificate files
To do that, you have to update the file ```/opt/tak/CoreConfig.xml```
```
nano /opt/tak/CoreConfig.xml
```
