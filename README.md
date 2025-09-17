# takserver-install-command
Simple readme to explain how to install a takserver on a Ubuntu server

# Requirements
- A server with Ubuntu 22.04 LTS
- A .deb file from tak.gov - version CORE "UBUNTU" (file mane look like "takserver_5.5-RELEASE53_all.deb")
- A domain pointing your server

# Install TAK Server
## Add Postgresql repository (required for takserver)
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

## Update the systeme
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

## Install takserver
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

# Add SSL certificate with Let's Encrypt
## Install Let's Encrypt
Install snap
```
sudo apt install snap
```
Install cerbot with snap
```
sudo snap install --classic certbot
```
## Generate certificate for your domain
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
```
cd /opt/tak/certs
```
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
## Configure admin account
Create certificate for admin user
```
./makeCert.sh client <admin-login>
```
Create admin user. The password require some complexity: ```minimum of 15 characters including 1 uppercase, 1 lowercase, 1 number, and 1 special character from this list [-_!@#$%^&*(){}[]+=~`|:;<>,./?]```
```
java -jar /opt/tak/utils/UserManager.jar usermod -A -p '<admin-password>' <admin-login>
```
