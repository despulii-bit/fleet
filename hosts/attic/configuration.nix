{ config, pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # ========================================================================
  # Bootloader & Filesystem
  # ========================================================================
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.growPartition = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # ========================================================================
  # Permanent Static Network Configuration
  # ========================================================================
  networking.hostName = "attic";
  networking.useDHCP = false; # Disabled global DHCP to enforce static routing

  # Locks down your desired architecture IP address permanently
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.10";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Explicitly opens ports for both SSH management and your binary cache daemon
  networking.firewall.allowedTCPPorts = [ 22 8080 ];

  # ========================================================================
  # Services & Virtualization Hardware
  # ========================================================================
  services.qemuGuest.enable = true;

  # Attic Daemon Service Configuration
  services.atticd = {
    enable = true;
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
    wantedBy = [ "multi-user.target" ]; # Forces auto-enable on cold boot
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  # ========================================================================
  # System Activation Bootstrapping (Secrets Injection)
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

  system.stateVersion = "26.05";
}
