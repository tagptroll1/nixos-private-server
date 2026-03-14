{ pkgs, ... }: {
  environment.etc."motd.sh" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      echo ""
      echo "  ┌─────────────────────────────────────────┐"
      echo "  │                                         │"
      echo "  │   󰒋  $(hostname)                        │"
      echo "  │                                         │"
      echo "  │   OS      NixOS                         │"
      echo "  │   User    $(whoami)                     │"
      echo "  │   Secret  $secret                       │"
      echo "  └─────────────────────────────────────────┘"
      echo ""
    '';
  };

  programs.bash.loginShellInit = "/etc/motd.sh";

	services = {
		openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "yes";
				PasswordAuthentication = true;
			};
		};
		qemuGuest.enable = true;
	};

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
}
