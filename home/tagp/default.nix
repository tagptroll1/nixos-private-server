{ lib, ... }: {
  imports = [
    ./programs.nix
    ./services.nix
  ];

  # Required — tells home-manager what version to base state on
  home.stateVersion = "25.11";
  home.username = "tagp";
	home.homeDirectory = lib.mkForce "/home/tagp";
}
