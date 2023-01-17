{ ... }: {

  imports = [ ./service.nix ];

  virtualisation.libvirtd.enable = true;
  security.polkit.enable = true;
}
