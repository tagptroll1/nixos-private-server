{ ... }: {
	users.users.tagp = {
		isNormalUser = true;
		description = "Main account";
		extraGroups = [ "wheel" "networkmanager" "docker" ];
		openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiXPaVoHFnjA3wTgXLvWPPMUfpWi+C3hnCFBYtlpMYs thomas@petersson.priv.no" ];
	};

	# System user for pulling and deploying Karoline's static site
	users.users.staticbuilder = {
		isSystemUser = true;
		group = "nginx";
	};
}
