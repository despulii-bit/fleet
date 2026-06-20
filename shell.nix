{ pkgs, deploy-rs, system }:

pkgs.mkShell {
  name = "deploy-shell";

  # This automatically injects the SSH options whenever you enter the shell
  env = {
    NIX_SSHOPTS = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
  };

  packages = [
    deploy-rs.packages.${system}.default
  ];

  shellHook = ''
    echo "🚀 deploy-rs environment loaded with SSH overrides!"
    echo "Run 'deploy' to update all nodes, or 'deploy .#k3s-control-1' for a specific host."
  '';
}
