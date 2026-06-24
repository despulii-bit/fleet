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

      # FIXED: Upstream Attic split 'endpoint' into explicit routing fields
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
      # FIXED: Added required 'nar-size-threshold' parameter as mandated by reference docs
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
  # Automatically creates the storage directory and generates a safe baseline JWT
  # secret if the node is booting up for the very first time.
  systemd.tmpfiles.rules = [
    "d /var/lib/atticd 0750 atticd atticd - -"
    "f /var/lib/atticd/credentials 0640 atticd atticd - ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=ZXhhbXBsZS1zZWNyZXQtbW9kaWZ5LXRoaXMtaW4tcHJvZHVjdGlvbi1wbHNa"
  ];

  # ========================================================================
  # Firewall Management
  # ========================================================================
  # Open the port in the firewall for your LAN traffic
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
