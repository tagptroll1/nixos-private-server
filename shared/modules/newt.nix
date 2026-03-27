# Parameterized Pangolin tunnel (newt) module.
# Usage:
#   (import ../../shared/modules/newt.nix {
#     endpoint = "https://pangolin.yesbutmaybe.no";
#     secretIdKey = "newt-id";
#     secretSecretKey = "newt-secret";
#   })
{ endpoint, secretIdKey ? "newt-id", secretSecretKey ? "newt-secret" }:

{ config, ... }: {
	sops.templates."newt.env".content = ''
		NEWT_ID=${config.sops.placeholder.${secretIdKey}}
		NEWT_SECRET=${config.sops.placeholder.${secretSecretKey}}
	'';

	services.newt = {
		enable = true;
		settings = {
			endpoint = endpoint;
		};
		environmentFile = config.sops.templates."newt.env".path;
	};

	systemd.services.newt.serviceConfig = {
		AmbientCapabilities = [ "CAP_NET_RAW" ];
	};
}
