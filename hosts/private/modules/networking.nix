{ hostConfig, ... }: {
	networking = {
		hostName = hostConfig.hostname;
		networkmanager.enable = false;
		useDHCP = false;
		firewall = {
			enable = true;
			allowedTCPPorts = [];
		};
		interfaces.${hostConfig.interface}.ipv4.addresses = [{
			address = hostConfig.ip;
			prefixLength = hostConfig.prefixLength;
		}];
		defaultGateway = hostConfig.gateway;
		nameservers = hostConfig.nameservers;
	};
}
