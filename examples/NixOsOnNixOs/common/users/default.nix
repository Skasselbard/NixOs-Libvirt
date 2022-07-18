{ lib, config, pkgs, ... }:

with lib;
with pkgs;
{
  options = {
    sshKey = mkOption{
      type = types.str;
      default = "";
    };
  };

  config = {
    users.mutableUsers = false;
    users.extraUsers = {
      root.openssh.authorizedKeys.keys = [ config.sshKey ];
       
      nixi = {
        isNormalUser = true;
        extraGroups = ["wheel" "libvirtd"];
        openssh.authorizedKeys.keys = [ config.sshKey ];
      };
    };
  };
}