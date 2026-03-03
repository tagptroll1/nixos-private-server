{ ... }: {
	networking = {
		hostName = "private"; # Define your hostname.
		networkmanager.enable = true;
		firewall = {
			enable = true;
			allowedTCPPorts = [];
		};
		interfaces.ens18.ipv4.addresses = [{
			address = "10.0.20.5";
			prefixLength = 24;
		}];
		defaultGateway = "10.0.20.1";
		nameservers = [ "8.8.8.8" "1.1.1.1" ];
	};
}
