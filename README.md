# Configuration

## DuckDNS and Caddy

Visit https://www.duckdns.org and then create an account.

Once in, add a subdomain to the duckdns.org domain. Once created, modify the IP to point to your internal IP of the service.

This way, when caddy runs, it'll use that hostname and also get a valid, signed lets encrypt certificate for the internal IP, which makes all the clients of vaultwarden happy, when defining a self-hosted endpoint.

This also provides HTTPS protection for all services that run behind caddy.

## Vaultwarden

Create a vaultwarden/vwdata folder where ever the root of the self hosted stack is going to be housed.

Adjust the override for vaultwarden to point to this location.