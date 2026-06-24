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
        modules = [
          ./shared/default.nix          # Loads your base configuration (SSH, Firewall, Keys)
          ./hosts/attic/configuration.nix # Loads host-specific hardware/settings
          ./hosts/attic/atticd.nix        # Loads your attic binary cache service
        ];
      };
      "k3s-control-01" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./shared/default.nix
          ./hosts/k3s/configuration.nix
        ];
      };
    };

    # 2. Colmena deployment map (Used by your local cron/timer agents for pull deployments)
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
      };

      # Mirroring the exact same module files so Colmena and your bootstrap script see the same layout
      attic = { ... }: {
        imports = [
          ./shared/default.nix
          ./hosts/attic/configuration.nix
          ./hosts/attic/atticd.nix
        ];
      };
      "k3s-control-01" = { ... }: {
        imports = [
          ./shared/default.nix
          ./hosts/k3s/configuration.nix
        ];
      };
    };
  };
}
