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
}
