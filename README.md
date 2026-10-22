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
working; only outside access to the database stops. Payram images released
after this fix also make the embedded Postgres listen only inside the
container; on those, `docker pull payramapp/payram:latest && systemctl
restart payram` closes it too. Droplets do not pull new images by
themselves.

### After the port was open

Anyone who reached port 5432 could read and change the payments database,
and Postgres keeps no record of who logged in. On a droplet that had it
open, check in the dashboard:

- **Members:** nobody you don't know, and no role was raised.
- **API keys:** revoke every key and create new ones for your integrations.
- **Payout recipients, cold wallet and fund-collector addresses:** each is
  an address you chose. Swept funds and payouts go to them.
- **Webhooks:** every URL is yours.
- **RPC nodes:** only providers you set. A node you don't control can
  report deposits that never happened.
- **Payout limits and auto-approve:** as you set them.

Then have every member change their password. Customer data (emails,
payment history) may have been read.
