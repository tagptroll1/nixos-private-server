{ ... }: {
	nixpkgs.overlays = [
		(final: prev: {
			proton-pass-cli = final.callPackage ../../shared/proton-pass-cli/package.nix {};
		})
	];
}
