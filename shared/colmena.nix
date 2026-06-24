{ pkgs, config, ... }: {

  # ========================================================================
  # Continuous Deployment (Colmena Pull Engine)
  # ========================================================================

  # 1. Define the worker service that executes the pull-and-apply logic
  systemd.services.colmena-pull-apply = {
    description = "Automatically pull fleet configuration and apply local upgrades via Colmena";

    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = with pkgs; [
      git
      coreutils
      gnutar
      gzip
      colmena # Pulls the binary directly from pkgs
    ];

    serviceConfig = {
      Type = "oneshot";
      # Runs safely out of a temporary deployment runtime path
      WorkingDirectory = "/var/lib/colmena-fleet";
    };

    script = ''
      REPO_URL="https://github.com/your-username/your-cluster-fleet.git"
      TARGET_DIR="/var/lib/colmena-fleet"

      echo "Syncing repository..."
      if [ ! -d "$TARGET_DIR/.git" ]; then
        rm -rf "$TARGET_DIR"
        git clone "$REPO_URL" "$TARGET_DIR"
        cd "$TARGET_DIR"
      else
        cd "$TARGET_DIR"
        git fetch origin main
      fi

      # Check if local commit matches the upstream branch tracking point
      LOCAL_HASH=$(git rev-parse HEAD)
      REMOTE_HASH=$(git rev-parse origin/main)

      if [ "$LOCAL_HASH" != "$REMOTE_HASH" ] || [ ! -f /var/lib/nixos-bootstrapped ]; then
        echo "New configuration profile detected! Upstream: $REMOTE_HASH"
        git reset --hard origin/main

        echo "Executing Colmena local convergence build..."
        colmena apply-local --flake .

        echo "System converged successfully to state: $REMOTE_HASH"
        touch /var/lib/nixos-bootstrapped
      else
        echo "System state is already fully identical to Git main branch ($LOCAL_HASH). Skipping build evaluation."
      fi
    '';
  };

  # 2. Define the clock scheduler trigger for the service execution loop
  systemd.timers.colmena-pull-apply = {
    description = "Scheduled check trigger for Colmena Git tracking synchronization";

    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "10m";
      Persistent = true;
    };

    wantedBy = [ "timers.target" ];
  };
}
