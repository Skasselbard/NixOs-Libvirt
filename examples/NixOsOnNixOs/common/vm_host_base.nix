{pkgs, ...}:
{
  # The partitioning is important!
  # We use the paths defined there in this file.
  imports = [
    ./virtual_machines/partitioning.nix
    ./virtual_machines/boot.nix
  ];

  # Start a systemd service to reconfigure this base vm into a specialized machine
  systemd.services.nixos_configure = {
      path = with pkgs; [nixos-rebuild]; # tell systemd where nixos-rebuild is
      environment = { 
        # expose the nixpkgs path from the local machine to the systemd service
        NIX_PATH = "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos";
        };
      # A systemd option everybody uses. Probably important; don't know why ¯\_(ツ)_/¯
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes"; # I know this option is important to make the service remain in the systemctl list after it exited. If everything worked we reboot anyway, but it can't hurt.
      };
      # The sevice runs a script which executes nixos-rebuild with the boot option
      # and reboots. 'nixos-rebuild switch' seems to fail because it restarts systemd
      # which in turn kills this script in the process before it can exit successfully :D
      script = ''
        nixos-rebuild boot -I nixos-config=/etc/nixos/hosts/self/configuration.nix
        reboot
      '';
    };
}