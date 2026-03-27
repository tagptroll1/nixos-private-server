{ hostConfig, ... }: {
	services.openssh = {
		enable = true;
		listenAddresses = [{
			addr = hostConfig.ip;
			port = 22;
		}];
		settings = {
			PermitRootLogin = "no";
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
		};
	};
}
