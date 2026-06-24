{ config, pkgs, ... }: {

  # ========================================================================
  # Attic Daemon Service Configuration
  # ========================================================================
  services.atticd = {
    enable = true;

    # Explicitly pass the path to satisfy the NixOS module assertion check
    environmentFile = "/var/lib/atticd/credentials";

    settings = {
      listen = "[::]:8080";
      api-endpoint = "http://192.168.1.10:8080";
      substituter-endpoint = "http://192.168.1.10:8080";

      storage = {
        type = "local";
        path = "/var/lib/atticd/storage";
      };

      database = {
        url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
      };

      chunking = {
        nar-size-threshold = 65536;
        min-size = 16384;
        avg-size = 65536;
        max-size = 262144;
      };
    };
  };

  # ========================================================================
  # Systemd Integration Upgrades
  # ========================================================================
  systemd.services.atticd = {
    # 1. Force the service to target multi-user.target so it enables on first boot
    wantedBy = [ "multi-user.target" ];

    # 2. Add an explicit dependency mapping to prevent race conditions during bootstrap
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  # ========================================================================
  # System Activation Bootstrapping
  # ========================================================================
  system.activationScripts.atticd-secrets-bootstrap = {
    text = ''
      mkdir -p /var/lib/atticd
      if [ ! -f /var/lib/atticd/credentials ]; then
        echo "ATTIC_SERVER_TOKEN_HS256_SECRET_BASE64=ZXhhbXBsZS1zZWNyZXQtbW9kaWZ5LXRoaXMtaW4tcHJvZHVjdGlvbi1wbHNa" > /var/lib/atticd/credentials
      fi
      chown -R atticd:atticd /var/lib/atticd
      chmod 750 /var/lib/atticd
      chmod 640 /var/lib/atticd/credentials
    '';
  };

  # ========================================================================
  # Firewall Management
  # ========================================================================
  networking.firewall.allowedTCPPorts = [ 8080 ];
}
