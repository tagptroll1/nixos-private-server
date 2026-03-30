{ ... }: {
	services.changedetection-io = {
		enable = true;
		listenAddress = "localhost";
		port = 5000;
		behindProxy = true;
		baseURL = "https://change.ybmn.no";
		webDriverSupport = true;
	};
}
