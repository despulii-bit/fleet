{ config, pkgs, ... }: {

  # ========================================================================
  # Attic Daemon Service Configuration
  # ========================================================================
  services.atticd = {
    enable = true;

    # File containing the JWT signing secret
    environmentFile = "/var/lib/atticd/credentials";

    settings = {
      # Listen on all interfaces so your LAN VMs can reach it
      listen = "[::]:8080";

      # Explicit upstream routing fields
      api-endpoint = "http://192.168.1.10:8080";
      substituter-endpoint = "http://192.168.1.10:8080";

      # Storage backend configuration (Local Filesystem)
      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      # Database configuration (SQLite for simple LAN setups)
      database = {
        url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
      };

      # Chunking optimization parameters
      chunking = {
        nar-size-threshold = 65536; # 64 KiB threshold to trigger deduplication
        min-size = 16384;           # 16 KiB
        avg-size = 65536;           # 64 KiB
        max-size = 262144;          # 256 KiB
      };
    };
  };

  # ========================================================================
  # Automated Bootstrap Automation (Pre-seed Secrets)
  # ========================================================================
  # This runs right before atticd starts, ensuring the directory and baseline
  # credentials file exist with the correct permissions on the very first boot.
  systemd.services.atticd.preStart = ''
    mkdir -p /var/lib/atticd
    if [ ! -f /var/lib/atticd/credentials ]; then
      echo "ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=ZXhhbXBsZS1zZWNyZXQtbW9kaWZ5LXRoaXMtaW4tcHJvZHVjdGlvbi1wbHNa" > /var/lib/atticd/credentials
    fi
    chown -R atticd:atticd /var/lib/atticd
    chmod 750 /var/lib/atticd
    chmod 640 /var/lib/atticd/credentials
  '';

  # ========================================================================
  # Firewall Management
  # ========================================================================
  # Open the port in the firewall for your LAN traffic
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
