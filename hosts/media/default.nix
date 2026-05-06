{ modulesPath, ... }: {
	imports = [
		(modulesPath + "/profiles/qemu-guest.nix")
		./hardware-configuration.nix

		# Shared modules
		../../shared/modules/base.nix
		../../shared/modules/overlays.nix
		../../shared/modules/sshd.nix

		# Host-specific modules
		./modules/networking.nix
		./modules/users.nix
		./modules/packages.nix
		./modules/storage.nix
		./modules/gpu.nix
		./modules/tailscale.nix
		./modules/caddy.nix
		./modules/immich.nix
		./modules/immich-public-proxy.nix
		./modules/jellyfin.nix
	];

	sops.age.keyFile = "/etc/age/host.key";
	sops.secrets = {
		"caddy/domeneshop_token" = {
			sopsFile = ./secrets/caddySecret.yaml;
			key = "token";
			owner = "caddy";
		};
	};

	services.qemuGuest.enable = true;
}
