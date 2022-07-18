{ lib, config, ... }:
with lib;
{
  options = {
    boot-uuid = mkOption{type = types.str;};
    root-uuid = mkOption{type = types.str;};
  };
  # The partitioning has to be done manually first (e.g. with parted)
  # After partitioning you can get the uuids from the patitions and use them in the host config
  # This manual work is one of the reason I like to keep the host config as minimal and static as possible
  config.fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/${config.boot-uuid}";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-uuid/${config.root-uuid}";
      fsType = "ext4";
      autoResize = true; # grow if partition grows
    };
  };
}