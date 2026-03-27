{ config, pkgs, hostConfig, ... }:
let
  inherit (pkgs) it-tools;
in {
  networking = {
    hostName = hostConfig.hostname;
    networkmanager.enable = false;
    useDHCP = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 8080 ];
    };
    interfaces.${hostConfig.interface}.ipv4.addresses = [{
      address = hostConfig.ip;
      prefixLength = hostConfig.prefixLength;
    }];
    defaultGateway = hostConfig.gateway;
    nameservers = hostConfig.nameservers;
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/tagptroll1/caddy-dns-domeneshop@v0.1.3"
      ];
      # Leave as "" for first build — it will fail and print:
      #   got: sha256-<hash>
      # Paste that value here and rebuild.
      hash = "sha256-sFRz/HHY6eRbBoWq00qBuUa56gLz1sWUmJTU3aNpVMI=";
    };

    globalConfig = ''
      acme_dns domeneshop {
        token  {env.DOMENESHOP_API_TOKEN}
        secret {env.DOMENESHOP_API_SECRET}
      }
    '';

    virtualHosts =
      let
        # Generates both the canonical HTTPS host and a www+http redirect
        mkVHost = domain: upstream: {
          "${domain}" = {
            extraConfig = ''
              reverse_proxy ${upstream}
            '';
          };
          "www.${domain}" = {
            extraConfig = ''
              redir https://${domain}{uri} permanent
            '';
          };
        };
      in
        (mkVHost "status.ybmn.no" "127.0.0.1:3001")
        // (mkVHost "file.ybmn.no" "127.0.0.1:3030")
        // (mkVHost "files.ybmn.no" "127.0.0.1:3030")
        // (mkVHost "home.ybmn.no" "127.0.0.1:8082")
        // (mkVHost "grafana.ybmn.no" "10.0.0.5:3000")
        // {
          # IT Tools: static SPA served directly from nix store (no container needed)
          "tools.ybmn.no" = {
            extraConfig = ''
              root * ${it-tools}/lib
              file_server
            '';
          };
          "www.tools.ybmn.no" = {
            extraConfig = "redir https://tools.ybmn.no{uri} permanent";
          };
          # Proxmox: backend uses self-signed cert; tls_insecure_skip_verify is backend-only.
          # DNS: proxmox.ybmn.no must point to 10.0.20.5 (this host), not 10.0.0.69 directly.
          "proxmox.ybmn.no" = {
            extraConfig = ''
              reverse_proxy 10.0.0.69:8006 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
            '';
          };
          "www.proxmox.ybmn.no" = {
            extraConfig = "redir https://proxmox.ybmn.no{uri} permanent";
          };
        }
      ;
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.secrets."caddy/domeneshop_token".path;
  };
}
