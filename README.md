# ThinkServer

I was not able to buy a Raspberry Pi 4 so I am now using my old Lenovo ThinkPad T440s as my home server replacing the old Raspberry Pi 2 that became too slow for my current needs.

![Dashboard](homepage.png)

## Main goal

Main goals of my home server are network wide ad blocking and a media server with automated movies and TV shows downloads accessible also from the outside thanks to Tailscale.

## Software

- [Plex Media Server](https://www.plex.tv/)
- [Sonaar](https://sonarr.tv/)
- [Radarr](https://radarr.video/)
- [FlareSolverr](https://github.com/FlareSolverr/FlareSolverr)
- [Transmission](https://transmissionbt.com/)
- [AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)
- [Homepage](https://gethomepage.dev/latest/)
- [Home Assistant](https://www.home-assistant.io/)
- [Prowlarr](https://prowlarr.com/)
- [Shinkro](https://github.com/varoOP/shinkro)
- [Tailscale](https://tailscale.com/)

### Docker

Most of the software runs in Docker for easier management. See [docker-compose.yml](https://github.com/igorkulman/thinkserver/blob/main/docker-compose.yml) for exact configuration.

```bash
mkdir docker-services
cd docker-services
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/docker-compose.yml
docker-compose up -d
```

#### Docker DNS

I encountered problems where Docker containers were not able to access DNS, probably because of AdGuardHome. I fixed it by setting Docker DNS to directly use Cloudflare and Google DNS.

```bash
sudo nano /var/snap/docker/current/config/daemon.json # because Ubuntu Server
```

```json
{ "dns" : [ "1.1.1.1" , "8.8.8.8" ] }
```

```bash
sudo snap restart docker
```

### Direct installation

Tailscale needs to be installed directly

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-exit-node --accept-dns=false
```

#### Plex over Tailscale

To be able to use Plex over Tailscale I had to add its Tailscale address (http://100.x.y.z:32400) to `Settings` | `Network` | `Custom server access URLs` (only visible after showing advanced settings).

## Reduce power consumption

### Remove external battery

The Thinkpad T440s includes a smaller internal battery and a bigger removable external battery. I removed the external battery to prolong its lifespan and reduce the heat generated charging it.

### Disable sleep on lid close

```bash
sudo nano /etc/systemd/logind.conf
```

set `HandleLidSwitch=ignore`, `LidSwitchIgnoreInhibited=no` and 

```bash
sudo service systemd-logind restart
```

### Turn off display when lid closed

Based on https://askubuntu.com/a/1117586

```bash
sudo apt-get install acpi-support vbetool
sudo echo "event=button/lid.*" > /etc/acpi/events/lid-button
sudo echo "action=/etc/acpi/lid.sh" >> /etc/acpi/events/lid-button
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/lid.sh
chmod +x lid.sh
sudo cp lid.sh /etc/acpi/lid.sh
```

### Disable Turbo Boost

Based on https://askubuntu.com/a/619881

```bash
sudo apt-get install msr-tools
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/turbo-boost.sh
chmod +x turbo-boost.sh
./turbo-boost.sh disable
```

### Disable unused hardware

```bash
sudo modprobe -r iwlwifi # Wi-Fi
sudo modprobe -r btusb # Bluetooth
sudo modprobe -r snd_hda_intel # Sound
```

### PowerTOP

Based on https://rhea.dev/articles/2017-07/Home-server-Power-saving

```bash
sudo apt-get install powertop
sudo powertop --calibrate
```

```bash
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/powertop.service
sudo cp powertop.service /lib/systemd/system/powertop.service
sudo systemctl enable --now powertop
```

### Disable the red LED

Disabling the red power LED on the lid is not really a power saving features, it is more an annoyance to remove, especially when the Thinkpad is placed in some visible place.

```bash
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/led-off.sh
chmod +x led-off.sh
./led-off.sh
```

### Power consumption measurements

In idle all the docker containers are running but just AdGuardHome responds to DNS queries from my network, the other containers do not really do anything.

| State 							| Power usage 		|
| ---- 								| ----------------- |
| Idle 								|              	5 W |
| Plex (playback) 					|               8 W |
| Plex (playback with transcoding)  |              17 W |

All the measurements were done with [Solight DT26](https://www.solight.cz/en/detailsklk.aspx?sklk_id=1RS1000201).

## Network shares

### Samba

```bash
wget https://raw.githubusercontent.com/igorkulman/thinkserver/main/shares.conf
sudo nano /etc/samba/smb.conf
```
add

```
include = /home/igorkulman/shares.conf
```

and restart Samba

```bash
sudo service smbd restart
```

### NFS

NFS is faster than Samba so I prefer it for accessing the data from macOS machines.

```bash
sudo apt install nfs-kernel-server
sudo nano /etc/exports
```

add

```
/media/data/downloads *(rw,sync,no_subtree_check,root_squash,insecure)
/media/data/backup *(rw,sync,no_subtree_check,root_squash,insecure)
/media/data/Movies *(rw,sync,no_subtree_check,root_squash,insecure)
/media/data/TVShows *(rw,sync,no_subtree_check,root_squash,insecure)
```

and reload NFS

```bash
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```