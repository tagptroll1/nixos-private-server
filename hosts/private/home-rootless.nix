{ lib, inputs, ... }: {
  imports = [
		inputs.quadlet-nix.homeManagerModules.quadlet
    ./containers/hello    # rootless containers go here
  ];

  home.stateVersion = "25.11";
  home.username = "podman";
  home.homeDirectory = lib.mkForce "/var/lib/podman";
}
