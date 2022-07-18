{ lib, config, ... }:
with lib;
{
  options = {
    hostname = mkOption{type = types.str;};
    ip = mkOption{type = types.str;};
    interface = mkOption{type=types.str;};
    bridgename = mkOption{type=types.str;};
  };

  config = {
    networking = {
      hostName = config.hostname;
      # Configure a Bridge for VMs to connect to
      bridges = {
        "${config.bridgename}" = {
          # add the interface configured by "config.interface" to the bridge
          interfaces = [config.interface];
        };
      };
      # Configure the bridge connection to the LAN.
      # Thats what you usually do with a plain interface config.
      interfaces.${config.bridgename} = {
        ipv4.addresses = [ {
            address = config.ip;
            prefixLength = 24;
          } ];
      };
      defaultGateway = {
        address = "192.168.1.1"; # router address
        interface = "${config.bridgename}"; # go to other nets through the bridge
      };
    };
  };
}