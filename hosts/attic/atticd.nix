{ config, pkgs, ... }: {

  # ========================================================================
  # Attic Daemon Service Configuration
  # ========================================================================
  services.atticd = {
    enable = true;

    # ADD THIS BACK: It satisfies the module's compiler assertion check.
    # The activation script below guarantees this path is populated.
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
  # System Activation Bootstrapping
  # ========================================================================
  # Runs DURING 'nixos-rebuild switch' before systemd loads the service,
  # preventing the "Failed to load environmentFile" systemd resource crash.
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
