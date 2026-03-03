{ pkgs, modulesPath, inputs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      (modulesPath + "/profiles/qemu-guest.nix")
    ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "private"; # Define your hostname.
  networking.networkmanager.enable = true;
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

  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_GB.UTF-8";
  console.keyMap = "no-latin1";

  users.users.tagp = {
    isNormalUser = true;
    description  = "Main account";
    initialPassword = "password";
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINiXPaVoHFnjA3wTgXLvWPPMUfpWi+C3hnCFBYtlpMYs thomas@petersson.priv.no" ];
  };

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

  programs.neovim = {
   enable = true;
   defaultEditor = true;
   package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
  };

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;
	services.qemuGuest.enable = true;

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

  system.stateVersion = "25.11"; 
}

