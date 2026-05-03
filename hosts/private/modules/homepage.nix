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
				"Home" = [
					{ "Home Assistant" = { href = "https://ass.ybmn.no"; description = "Smart home";  icon = "home-assistant.png"; }; }
					{ "Zigbee2MQTT"    = { href = "https://z2m.ybmn.no"; description = "Zigbee mesh"; icon = "zigbee2mqtt.png"; }; }
				];
			}
			{
				"Media" = [
					{ "Immich" = { href = "https://immich.ybmn.no"; description = "Photos"; icon = "immich.png"; }; }
				];
			}
			{
				"Monitoring" = [
					{ "Grafana"          = { href = "http://10.0.0.5:3000";  description = "Metrics";      icon = "grafana.png"; }; }
					{ "Uptime Kuma"      = { href = "https://status.ybmn.no"; description = "Status";       icon = "uptime-kuma.png"; }; }
					{ "Change Detection" = { href = "https://change.ybmn.no"; description = "Page changes"; icon = "changedetection-io.png"; }; }
				];
			}
			{
				"Hypervisors" = [
					{ "Proxmox home01" = { href = "https://10.0.0.69:8006"; description = "Server VLAN";    icon = "proxmox.png"; }; }
					{ "Proxmox home02" = { href = "https://10.2.0.69:8006"; description = "NAS / VLAN 200"; icon = "proxmox.png"; }; }
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
