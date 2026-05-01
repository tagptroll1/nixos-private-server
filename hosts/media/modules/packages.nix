{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    vim
    proton-pass-cli
    git
    wget
    curl
    htop
    btop
    sops
    pciutils
    nvtopPackages.nvidia
  ];
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
