{ pkgs, modulesPath, lib, config, ... }: {

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # ========================================================================
  # Hardware & Bootloader Alignment
  # ========================================================================
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda"; # Matches your VirtIO OpenTofu disk
  boot.growPartition = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  services.qemuGuest.enable = true;

  # ========================================================================
  # Networking Configuration
  # ========================================================================
  # Hostname is set by cloud-init on boot (e.g., k3s-control-01, k3s-worker-01)
  networking.useDHCP = true;

  # Open the required ports for k3s control plane, workers, and cluster networking
  networking.firewall.allowedTCPPorts = [
    6443 # Kubernetes API Server
    2379 # etcd client port (if doing multi-control embedded HA)
    2380 # etcd peer port (if doing multi-control embedded HA)
    10250 # Kubelet API
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # Flannel VXLAN overlay network tracking
  ];

  # ========================================================================
  # Unified K3s Service Management
  # ========================================================================
  services.k3s = {
    enable = true;

    # DYNAMIC ROLE SELECTION:
    # If the hostname contains "control", act as a server. Otherwise, act as an agent (worker).
    role = if (lib.strings.hasInfix "control" config.networking.hostName) then "server" else "agent";

    # Global flags passed directly to the execution binary
    extraFlags = toString ([
      # Tell the node where to find the primary cluster orchestrator
      # (Omit or change this string dynamically if configuring control-01)
      "--server https://192.168.1.11:6443"

      # The shared cluster secret token used by nodes to safely authenticate and join
      "--token K10yourSuperSecretClusterTokenGoesHere::server"

      # Disable trailing components you might want to handle via Helm later (Optional)
      "--disable traefik"
    ]);
  };

  # Dependency package needed for cluster storage volume attachment
  environment.systemPackages = with pkgs; [
    openiscsi
  ];

  system.stateVersion = "26.05";
}
