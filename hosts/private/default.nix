{ modulesPath, ... }: {
	imports = [
		(modulesPath + "/profiles/qemu-guest.nix")
		./hardware-configuration.nix
		./modules/nix-configuration.nix
		./modules/overlays.nix
		./modules/boot.nix
		./modules/networking.nix
		./modules/users.nix
		./modules/services.nix
		./modules/packages.nix
		./modules/podman.nix

		# Containers
		./containers/hello
	];

	time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "no-latin1";

	sops.age.keyFile = "/etc/age/host.key";
	sops.secrets = {
		"motd/secret" = {
			sopsFile = ./secrets/motdSecret.yaml;
			key = "secret";
			owner = "tagp";
		};
		"hello/secret" = {
			sopsFile = ./containers/hello/secret.yaml;
			key = "secret";
			owner = "tagp";
		};
	};
}
