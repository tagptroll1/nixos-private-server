{ pkgs, ... }: {
	environment.systemPackages = with pkgs; [
		sops
		docker
		vim
		git
		curl
		htop
		btop
		wget
		bind       # DNS utilities (dig, nslookup)
		nixd
		gcc
		cargo
		rustup
	];

	programs.neovim = {
		enable = true;
		defaultEditor = true;
	};
}
