{ ... }: {
	services.homepage-dashboard = {
		enable = true;
		listenPort = 8082;
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
					{ "Grafana"     = { href = "https://grafana.ybmn.no";  description = "Metrics";     icon = "grafana.png"; }; }
					{ "Uptime Kuma" = { href = "https://status.ybmn.no";   description = "Status";      icon = "uptime-kuma.png"; }; }
					{ "Proxmox"     = { href = "https://proxmox.ybmn.no";  description = "Hypervisor";  icon = "proxmox.png"; }; }
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
