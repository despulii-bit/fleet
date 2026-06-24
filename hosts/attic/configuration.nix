{ pkgs, modulesPath, ... }: {
  imports = [
    ../../shared # <-- This automatically looks for and pulls in shared/default.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    ./atticd.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.growPartition = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  networking.hostName = "attic-server";
  networking.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.qemuGuest.enable = true;

  system.stateVersion = "26.05";
}
