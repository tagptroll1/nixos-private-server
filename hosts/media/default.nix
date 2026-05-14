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
		./modules/mealie.nix
		./modules/opencloud.nix
		./modules/immich.nix
		./modules/immich-public-proxy.nix
		./modules/jellyfin.nix
	];

	sops.age.keyFile = "/etc/age/host.key";
	sops.secrets = {
		"opencloud/shared_env" = {
			sopsFile = ./secrets/opencloudSecret.yaml;
			key = "shared_env";
		};
		"opencloud/admin_env" = {
			sopsFile = ./secrets/opencloudSecret.yaml;
			key = "admin_env";
		};
		"opencloud/collabora_env" = {
			sopsFile = ./secrets/opencloudSecret.yaml;
			key = "collabora_env";
		};
		"caddy/domeneshop_token" = {
			sopsFile = ./secrets/caddySecret.yaml;
			key = "token";
			owner = "caddy";
		};
	};

	services.qemuGuest.enable = true;
}
