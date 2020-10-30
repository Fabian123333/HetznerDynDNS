# HetznerDynDNS
Hetzner DynDNS Updater for DNS Console

The following variables need to be set in the `entrypoint.sh` in case it should be used standalone:

```
DNS_ID - the id of the DNS zone
RECORDS - the records you want to update (e.g. @, www)
API_TOKEN - your Hetzner API Token
```

Beside of this you need `dnsutils` `jq` and `curl` installed.
> apt install jq curl dnsutils

For the Docker Docker Compose Version you have to place your API Token to `secrets/api-token`, the other settings may be modified as described in the `docker-compose-sample.yml`
