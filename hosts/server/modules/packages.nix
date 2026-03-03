{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # pkgs.neovim is now nightly thanks to the overlay
    docker
		vim
    proton-pass-cli
    git
    wget
    curl
		htop
		btop
    # add more here
  ];
	programs.neovim = {
		enable = true;
		defaultEditor = true;
	};
}
