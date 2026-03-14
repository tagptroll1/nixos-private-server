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

	programs.bash.initExtra = ''
    export NIX_SHELL_DEPTH=$(( ''${NIX_SHELL_DEPTH:-0} + 1 ))

    _nix_shell_indicator() {
      if [[ -n "$IN_NIX_SHELL" ]]; then
        local label="''${name:-''${IN_NIX_SHELL}}"
        echo "(nix:''${NIX_SHELL_DEPTH}:''${label}) "
      fi
    }

    PS1='$(_nix_shell_indicator)'"$PS1"
  '';
}
