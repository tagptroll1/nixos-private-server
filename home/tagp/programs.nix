{ pkgs, ... }: {
  programs.git = {
    enable = true;
		extraConfig = {
			user.name = "thomas";
			user.email = "thomas@petersson.priv.no";
		};
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  home.packages = with pkgs; [
    # user-specific packages that don't need to be system-wide
    ripgrep
    fd
		tmux
		nixd
		gcc
		lua-language-server
		vscode-langservers-extracted
		bash-language-server
		marksman
  ];

	programs.bash = {
    enable = true;
    initExtra = ''
      export NIX_SHELL_DEPTH=$(( ''${NIX_SHELL_DEPTH:-0} + 1 ))

      _nix_shell_indicator() {
        local label=""
        local nix_paths=$(echo "$PATH" | tr ':' '\n' | grep -c '/nix/store')

        if [[ -n "$IN_NIX_SHELL" ]]; then
          label="''${name:-''${IN_NIX_SHELL}}"
        elif [[ $nix_paths -ge 1 ]]; then
          label="nix-shell"
        else
          return
        fi

        echo -n "(''${label}:''${NIX_SHELL_DEPTH})"
      }

      PS1='\[\e[0;36m\]$(_nix_shell_indicator)\[\e[0m\] \u@\h:\w\$ '

			export SOPS_AGE_KEY_FILE="/etc/age/host.key"
    '';
  };
}
