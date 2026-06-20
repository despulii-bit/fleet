{
  description = "NixOS VM deployment flake using deploy-rs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, deploy-rs, ... }@inputs:
    let
      system = "x86_64-linux"; # Matches your Vivobook architecture
      pkgs = import nixpkgs { inherit system; };
    in {

      # 1. Define your NixOS system configuration
      nixosConfigurations = {
        k3s-control-1 = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/k3s-control-1/configuration.nix ];
        };
      };

      # 2. Define the deployment configuration for deploy-rs
      deploy.nodes = {
        k3s-control-1 = {
          hostname = "k3s-control-1.tailb85ceb.ts.net";
          fastConnection = true;

          profiles.system = {
            sshUser = "deploy";
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.k3s-control-1;
            user = "root";
          };

        };
      };

      # 3. Dedicated development shell for running deployments
      devShells.${system}.default = import ./shell.nix {
        inherit pkgs deploy-rs system;
      };
      # Allows you to run `nix flake check` to validate everything
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
