{ modulesPath, pkgs, config, ... }: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  networking.hostName = "k3s-control-1";

  # Enable Tailscale core daemon safely and pass takeover flags directly
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/lib/tailscale/authkey";

    # Direct configuration via native NixOS module flags
    extraUpFlags = [
      "--force-reauth"
      "--ssh=false"
      "--replace-existing-device-with-same-hostname"
    ];
  };

  # 3. Secure firewall settings
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 22 ];
  };

  # 4. Your existing deploy user settings (WITH KEYS KEPT)
  users.users.deploy = {
    isNormalUser = true;
    group = "deploy";
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPU1hmzQe4YB3YZFklqjaS0+fHtVy1WiJGpyUcP8clDP opentofu-managed-vms"
    ];
  };
  users.groups.deploy = {};

  nix.settings.trusted-users = [ "root" "deploy" ];

  security.sudo.extraRules = [
    {
      users = [ "deploy" ];
      commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ];
    }
  ];

  # 5. CRITICAL: Re-enable the SSH Daemon so deploy-rs doesn't die mid-air
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  system.stateVersion = "26.05";
}
