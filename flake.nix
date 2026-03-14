{
  description = "Tagps NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
		#proton-pass-cli.url = "path:./shared/proton-pass-cli";
		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
  };

	outputs = { nixpkgs, home-manager, sops-nix, ...}@inputs:
	{
		nixosConfigurations = {
			private = nixpkgs.lib.nixosSystem {
				specialArgs = { inherit inputs; };
				modules = [
					sops-nix.nixosModules.sops
					./hosts/private
					home-manager.nixosModules.home-manager
					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.users.tagp = import ./home/tagp;
					}
				];
			};
		};
	};
}
