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
		nvim-config = {
			url = "github:tagptroll1/nvim";
			flake = false;
		};
		quadlet-nix = {                                    # add this
			url = "github:SEIAROTg/quadlet-nix";
		};
  };

	outputs = { nixpkgs, home-manager, sops-nix, quadlet-nix, ...}@inputs:
	let 
		hosts = import ./lib/hosts.nix;
	in
	{
		nixosConfigurations = {
			private = nixpkgs.lib.nixosSystem {
				specialArgs = { 
					inherit inputs;
					hostConfig = hosts.private;
				};
				modules = [
					sops-nix.nixosModules.sops
					quadlet-nix.nixosModules.quadlet
					./hosts/private
					home-manager.nixosModules.home-manager
					{
						home-manager.useGlobalPkgs = true;
						home-manager.useUserPackages = true;
						home-manager.extraSpecialArgs = { inherit inputs; hostConfig = hosts.private; };
						home-manager.users.tagp = import ./home/tagp;
						home-manager.users.podman = import ./hosts/private/home-rootless.nix;
					}
				];
			};
		};
	};
}
