{ pkgs, modulesPath, ... }: {
  imports = [
    ../../shared
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

  # FIXED: Matched to the exact flake output attribute name ".#attic"
  networking.hostName = "attic";

  networking.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  services.qemuGuest.enable = true;

  system.stateVersion = "26.05";
}
