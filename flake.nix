{
  description = "Cluster Fleet Infrastructure Repository";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }@inputs: {
    # 1. Standard NixOS configurations (Used by your initial systemd bootstrap script)
    nixosConfigurations = {
      attic = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/attic/configuration.nix ];
      };
      "k3s-control-01" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/k3s/configuration.nix ];
      };
    };

    # 2. Colmena deployment map (Used by your local cron/timer agents for pull deployments)
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      };

      # Inherit the host configuration modules directly
      attic = { ... }: { imports = [ ./hosts/attic/configuration.nix ]; };
      "k3s-control-01" = { ... }: { imports = [ ./hosts/k3s/configuration.nix ]; };
    };
  };
}
