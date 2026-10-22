# payram-digitalocean

DigitalOcean Marketplace 1-Click App for [Payram](https://payram.com) — the
self-hosted crypto payment gateway.

Packer template + provisioning scripts that build a DO Droplet snapshot which,
on first boot, runs `payramapp/payram:latest`.

## Close the database port on droplets created before this fix

Droplets built from earlier snapshots publish the embedded Postgres on
port 5432 to the internet, where it accepts the default `payram` login.
Docker-published ports bypass UFW, so the firewall rule alone does not
protect it. On each existing droplet, as root:

```bash
sed -i '/--publish 5432:5432/d' /etc/systemd/system/payram.service
ufw delete allow 5432/tcp
systemctl daemon-reload && systemctl restart payram
```

Payram itself, `payram-status` and backups through `docker exec` keep
working; only outside access to the database stops. Current Payram images
also make the embedded Postgres listen only inside the container, so a
droplet that pulls a new image is closed even before this change.
