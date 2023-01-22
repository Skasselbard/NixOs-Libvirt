{ pkgs, lib, config, ... }:
with lib; {
  # https://nixos.wiki/wiki/Declaration
  options = {
    libvirt.domains = mkOption {
      type = types.attrsOf (types.submodule
        ((import ./domain.nix).domain_options { inherit lib types; }));
      description = "A set fo domains";
      default = { };
      example = ''
        {
          domain1 = {
            memory.amount = 2048;
            memory.unit = "MiB";
            disks = {
              os = {
                type = "file";
                device = "disk";
                path = ./pat.to.os.qcow;
                target = "vda"
              }
              data = {
                type = "block";
                device = "disk";
                path = /dev/sdc;
                target = "vdb"
                readOnly = true
              }
            }
          }
          domain2 = {
            memory.amount = 2;
            memory.unit = "GiB";
            disks = {
              os = {
                type = "file";
                device = "disk";
                path = ./path/to/os.qcow;
                target = "vda"
                transient = true
              }
            }
          }
        };
      '';
    };
    nix_path = mkOption {
      type = types.envVar;
      default =
        "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
    };
  };
  config = let
    domains = (import ./domain.nix).gen_domain_xml {
      inherit lib;
      domains = config.libvirt.domains;
    };
  in {
    # systemd.services.libvirt_network =  "";
    # systemd.services.libvirt_base_image = "";
    # inspired by https://nixos.wiki/wiki/NixOps/Virtualization
    systemd.services = lib.mapAttrs' (name: domain:
      lib.nameValuePair "libvirtd-domain-${name}" {
        path = with pkgs; [ nixos-generators qemu libguestfs git ];
        environment = {
          NIX_PATH = config.nix_path;
          # NIX_REMOTE = "deamon";
        };
        preStart = concatStrings (builtins.attrValues (attrsets.mapAttrs
          (disk_name: disk:
            if disk.type == "nix" then
              (import ./scripts.nix).qcowFromNix {
                inherit disk;
                disk_name = "${name}-${disk_name}";
              }
            else
              "") domain.disks));
        after = [ "libvirtd.service" "nix-deamon.service" ];
        requires = [ "libvirtd.service" "nix-deamon.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          User = "root";
          Group = "nixbld";
        };
        script = (import ./scripts.nix).defineDomain {
          inherit pkgs name;
          xml = builtins.toFile "${name}.xml" domain.xml;
        };
        preStop = (import ./scripts.nix).stopDomain { inherit pkgs name; };
      }) domains;
  };
}
