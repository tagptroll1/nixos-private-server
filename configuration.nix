# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, modulesPath, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (modulesPath + "/profiles/qemu-guest.nix")
    ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "private"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "no-latin1";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tagp = {
    isNormalUser = true;
    description  = "Main account";
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiXPaVoHFnjA3wTgXLvWPPMUfpWi+C3hnCFBYtlpMYs thomas@petersson.priv.no" ];
  };


  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    docker
    vim
    git
		nixd
		gcc
    curl
    htop
    btop
    wget
		lua-language-server
		vscode-langservers-extracted
		bash-language-server
		marksman
  ];

  # List services that you want to enable:
  programs.neovim = {
   enable = true;
   defaultEditor = true;
   package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
  };
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "10.0.20.5";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.0.20.1";
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];


  systemd.services."nvim-config" = {
	  description = "Pull and override Nvim config";
	  after = [ "network-online.target" ];
	  wants = [ "network-online.target" ];
	  wantedBy = [ "multi-user.target" ];

	  serviceConfig = {
	    Type = "oneshot";
	    User = "tagp";
	    RemainAfterExit = true;
	  };

	  script =
	    let
	      inherit (pkgs) git;
	      configDir = "/home/tagp/.config/nvim";
	      repo = "https://github.com/tagptroll1/nvim";
	    in
	    ''
	      if [ -d ${configDir}/.git ]; then
		${git}/bin/git -C ${configDir} pull
	      else
		rm -rf ${configDir}
		${git}/bin/git clone ${repo} ${configDir}
	      fi
	    '';
	};
  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

