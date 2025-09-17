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
