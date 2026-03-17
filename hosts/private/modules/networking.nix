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

  # Caddy built with the domeneshop DNS-01 plugin
  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/domeneshop@v0.0.5"
      ];
      # Run `nix-prefetch` or let it fail once to get the correct hash
      hash = pkgs.lib.fakeHash;
    };

    # Global ACME config — domeneshop DNS challenge
    globalConfig = ''
      acme_dns domeneshop {
        token      {env.DOMENESHOP_API_TOKEN}
        secret     {env.DOMENESHOP_API_SECRET}
      }
    '';

    # Each virtualHost becomes a subdomain
    virtualHosts = {
      "status.ybmn.no" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3001
        '';
      };

      # Add future services here, e.g.:
      # "grafana.ybmn.no" = {
      #   extraConfig = ''
      #     reverse_proxy 10.0.10.X:3000
      #   '';
      # };
    };
  };

  # Inject domeneshop credentials from sops into caddy's systemd unit
  systemd.services.caddy.serviceConfig = {
    EnvironmentFile = config.sops.secrets."caddy/domeneshop_token".path;
  };
}
