{ lib, config, ... }:
with lib;
{
  options = {
    hostname = mkOption{type = types.str;};
    ip = mkOption{type = types.str;};
    interface = mkOption{type=types.str;};
  };

  # configure static ip
  # The interface will have a direct connection to the LAN via the configured host bridge
  config = {
    networking = {
      hostName = config.hostname;
      interfaces.${config.interface} = {
        ipv4.addresses = [ {
            address = config.ip;
            prefixLength = 24;
          } ];
      };
      defaultGateway = {
        address = "192.168.1.1";
        interface = "${config.interface}";
      };
    };
  };
}