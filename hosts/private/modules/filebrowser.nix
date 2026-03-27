{...}: {
	users.users.noodledrive.isSystemUser = true;
	users.users.noodledrive.group = "noodledrive";
	users.groups.noodledrive = {};

	systemd.tmpfiles.rules = [
		"d /mnt/vmdata/noodledrive 				0770 noodledrive noodledrive"
		"d /mnt/vmdata/noodledrive/files 	0770 noodledrive noodledrive"
	];

	services.filebrowser = {
		enable = true;
		user   = "noodledrive";
		group  = "noodledrive";
		openFirewall = false;  # Caddy handles external access

		settings = {
			port     = 3030;
			address  = "127.0.0.1";  # only listen locally
			root     = "/mnt/vmdata/noodledrive/files";
			database = "/mnt/vmdata/noodledrive/filebrowser.db";
		};
	};
}
