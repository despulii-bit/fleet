{ pkgs, ... }: {

  imports = [
      ./colmena.nix # <-- Include your brand new file right here!
    ];

  # ========================================================================
  # Core System & Nix Daemon Settings
  # ========================================================================
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    # Optimize storage usage by automatically hard-linking duplicate build files
    auto-optimise-store = true;

    # Cleaned: No placeholders to crash your initial builds!
    substituters = [
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # ========================================================================
  # Global Security & Access
  # ========================================================================
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes"; # Allows deploy-rs / colmena / bootstrap automation
      PasswordAuthentication = false; # Strict public-key only access
      KbdInteractiveAuthentication = false;
    };
  };

  # Centralized access management: ensures your admin key is universally applied
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpK4eJLFTIpz4oneETI291gjFTNYCxQgaIJOU0OEz7l i@vivobook-to-nixos"
    ];
  };

  # ========================================================================
  # Common System Environment
  # ========================================================================
  # Packages that you absolutely want available on every single node for maintenance
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    htop
    tmux
  ];

  # Set your regional preferences uniformly
  time.timeZone = "America/New_York"; # Or your preferred time zone, e.g., "America/New_York"
}
