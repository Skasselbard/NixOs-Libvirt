{...}:

{
  # This base configuration is largely stolen from Xe's blog (https://xeiaso.net/blog/morph-setup-2021-04-25)

  imports = [
    <nixpkgs/nixos/modules/profiles/minimal.nix>
    ./users
  ];

  # Clean /tmp on boot.
  boot.cleanTmpDir = true;

  # Automatically optimize the Nix store to save space
  # by hard-linking identical files together. These savings
  # add up.
  nix.autoOptimiseStore = true;

  # Limit the systemd journal to 100 MB of disk or the
  # last 7 days of logs, whichever happens first.
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.05"; # Did you read the comment?
}
