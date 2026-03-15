{ ... }: {
	users.groups.tagp = {};
  users.users.tagp = {
    isNormalUser = true;
		group = "tagp";
    description  = "Main account";
    extraGroups = [ "wheel" "podman" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiXPaVoHFnjA3wTgXLvWPPMUfpWi+C3hnCFBYtlpMYs thomas@petersson.priv.no" ];
  };

	users.groups.podman = {};
	users.users.podman = {
		isSystemUser = true;
		group = "podman";
		description = "Rootless podman service account";
		home = "/var/lib/podman";
		createHome = true;
		shell = pkgs.shadow + "/bin/nologin";
		linger = true;
		autoSubUidGidRange = true;
	};
}
