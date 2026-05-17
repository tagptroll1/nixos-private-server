{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    docker
		vim
    proton-pass-cli
    git
    wget
    curl
		htop
		btop
		sops
    # add more here
  ];
}
