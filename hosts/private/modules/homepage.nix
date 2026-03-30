{ ... }: {
	services.homepage-dashboard = {
		enable = true;
		listenPort = 8082;
		allowedHosts = "home.ybmn.no";
		settings = {
			title = "Home";
			headerStyle = "clean";
		};
		bookmarks = [
			{
				"Dev Tools" = [
					{ "IT Tools"  = [{ href = "https://tools.ybmn.no";  icon = "wrench.png"; }]; }
				];
			}
			{
				"Sites" = [
					{ "WordPress" = [{ href = "https://sletteposten.no"; icon = "wordpress.png"; }]; }
				];
			}
		];
		services = [
			{
				"Monitoring" = [
					{ "Grafana"     = { href = "http://10.0.0.5:3000";   description = "Metrics";    icon = "grafana.png"; }; }
					{ "Uptime Kuma" = { href = "https://status.ybmn.no";  description = "Status";     icon = "uptime-kuma.png"; }; }
					{ "Proxmox"          = { href = "https://10.0.0.69:8006";  description = "Hypervisor";  icon = "proxmox.png"; }; }
					{ "Change Detection" = { href = "https://change.ybmn.no"; description = "Page changes"; icon = "changedetection-io.png"; }; }
				];
			}
			{
				"Files" = [
					{ "FileBrowser" = { href = "https://file.ybmn.no"; description = "Files"; icon = "filebrowser.png"; }; }
				];
			}
		];
		widgets = [
			{ resources = { cpu = true; memory = true; disk = "/"; }; }
			{ datetime = { text_size = "xl"; format = { timeStyle = "short"; dateStyle = "short"; }; }; }
		];
	};
}
