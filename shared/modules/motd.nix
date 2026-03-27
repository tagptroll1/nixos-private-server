{ config, hostConfig, ... }: {
	environment.etc."motd.sh" = {
		mode = "0755";
		text = ''
			#!/bin/sh
			motd() {
				local secret=$(cat ${config.sops.secrets."motd/secret".path})
				local user=$(whoami)
				local host="${hostConfig.hostname}"
				local width=45

				pad() {
					local str="$1"
					local total="$2"
					local len=$(echo -n "$str" | wc -m)
					local spaces=$((total - len))
					printf "%s%*s" "$str" "$spaces" ""
				}

				echo ""
				echo "  ┌$(printf '─%.0s' $(seq 1 $width))┐"
				echo "  │$(printf ' %.0s' $(seq 1 $width))│"
				echo "  │   󰒋  $(pad "$host" $((width - 6)))│"
				echo "  │$(printf ' %.0s' $(seq 1 $width))│"
				echo "  │   OS      $(pad "NixOS" $((width - 11)))│"
				echo "  │   User    $(pad "$user" $((width - 11)))│"
				echo "  │   Secret  $(pad "$secret" $((width - 11)))│"
				echo "  │$(printf ' %.0s' $(seq 1 $width))│"
				echo "  └$(printf '─%.0s' $(seq 1 $width))┘"
				echo ""
			}
			motd
		'';
	};

	programs.bash.loginShellInit = "/etc/motd.sh";

	services.qemuGuest.enable = true;
}
