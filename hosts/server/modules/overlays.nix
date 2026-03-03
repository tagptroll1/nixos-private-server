{ inputs, ... }: {
  nixpkgs.overlays = [
    inputs.neovim-nightly.overlays.default
		(final: prev: {
      proton-pass-cli = final.callPackage ../../../shared/proton-pass-cli/package.nix {};
    })
  ];
}
