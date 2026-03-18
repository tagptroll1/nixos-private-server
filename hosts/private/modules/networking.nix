{ config, pkgs, hostConfig, ... }: {
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
      hash = "sha256-EI7Sgkt9aD5sF8jkpPWgYFwDORWeUNNDUPlIGkYmRUk=";
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
        # Add future services by appending with //
        # // (mkVHost "grafana.ybmn.no" "127.0.0.1:3000")
        # // (mkVHost "nextcloud.ybmn.no" "127.0.0.1:8080")
      ;
  };

  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.secrets."caddy/domeneshop_token".path;
  };
}
