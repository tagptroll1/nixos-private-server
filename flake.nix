{
  description = "Tagps NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		agenix = {
			url = "github:ryantm/agenix";
			inputs.nixpkgs.follows = "nixpkgs";
 	 	};
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
		#proton-pass-cli.url = "path:./shared/proton-pass-cli";
  };

	outputs = { nixpkgs, home-manager, agenix, ...}@inputs:
	{
		nixosConfigurations = {
			private = nixpkgs.lib.nixosSystem {
				specialArgs = { inherit inputs; };
				modules = [
					./hosts/server
					agenix.nixosModules.default
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
