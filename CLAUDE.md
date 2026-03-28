# NixOS Config — Rules

## Before configuring any NixOS service
Always look up the actual module options before writing config. Never guess option names.

1. Search the nix store on the relevant host:
   ```
   ssh tagp@private.ybmn.no "find /nix/store -path '*/nixos/modules/*' -name '*.nix' 2>/dev/null | xargs grep -l 'services.SERVICENAME' 2>/dev/null | grep -v drv | head -5"
   ```
2. Cross-reference with nixpkgs on GitHub or https://search.nixos.org/options

This exists because option names are not guessable — e.g. `namespaces` not `namespaceConfig`, `allowedHosts` not an env var override.

## Never run nixos-rebuild
System rebuilds are manual. Prepare config files, then tell the user:
> "Run `sudo nixos-rebuild switch --flake ~/nixos#<host>` on <host>"

Never execute it yourself under any circumstances.

## Which host owns what
- `hosts/private/` — private host (10.0.20.5), SSH: `tagp@private.ybmn.no`
- `hosts/public/` — public host (10.0.10.10), SSH: `tagp@public.ybmn.no`
- Grafana/Prometheus/Proxmox live on the Server subnet (10.0.0.x) — NOT in this repo
