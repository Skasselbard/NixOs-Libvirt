# https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
{
  disk_options = {lib, types, ...}: with lib; with types; {
    options = {
      type = mkOption{
        type = types.enum ["nix" "file" "block" "dir" "volume"]; #, "network", "nvme" or "vhostuser"
         description = ''
          The source type from which the disk is imported. See the "path" 
          option for the implications.
         '';
      };

      device = mkOption{
        type = types.enum ["disk"]; # "floppy" "cdrom" "lun"
        default = "disk";
        description = "Indicates how the disk is to be exposed to the guest OS.";
        };

      driver ={
        name = mkOption{
          type = types.enum ["qemu" "tap" "tap2" "phy" "file"];
          default = "qemu";
          description = "How to interpret the given disk (see libvirt documentation)";
        };
        type = mkOption{
          type = types.enum ["aio" "raw" "bochs" "qcow2" "qed" "fat"];
          default = "qcow2";
          description = ["The Subtype of the driver."];
        };
      };

      path = mkOption{
        type = types.path;
        description = ''
          A valid path on the host to the disk resource.
          The expected typoe of the resource depends on the disk.type.
          type = "file" -> path to a image file e.g. "/var/lib/libvirt/images/os.qcow2"
          type = "block" -> path to a device e.g. "/dev/sda"
          type = "dir" -> path to a directory that should be mounted
          type = "volume" -> not applicable! TODO: Or is it?
          type = "nix" -> path to a nix file.
                          This option is not backed by libvirt itself.
                          This option requires the disk.nix.out_dir option.
                          If the "nix" type is configured, a nix image is generated with
                          nixos-generate (nixos-generators package) during the startup
                          of the domains service. The resulting image (in the nix store)
                          is then used as a backing image for the actually used image in
                          disk.nix.out_dir. A positive side effect from this behavior is,
                          that you can base multiple domains on the same nix
                          configuration and have a single backing image for all domains.

                          In libvirt the image is used as a "file" based disk with a
                          path to the generated qcow file.

                          If you deploy your configuration remotely (e.g. nixops, 
                          colmena), make sure all files and paths are accessable and the output path is writable on the remote host.
                          Tip: if you assign a path to a 'let' variable,
                          the path will be copied in the nix store and on the remote 
                          host (tested with colmena). This is helpful e.g. if your nix
                          configuration depends on other nix files that are referenced
                          with relative paths. If you assign the configuration root 
                          directory to a variable all files will be accessable on the
                          host and the relative paths are reserved.
        '';
        example = "/var/lib/libvirt/images/os.qcow2";
      };

      nix = {
        size = mkOption{
          type=ints.positive;
            description = ''
              Only used for disk.type = "nix". Ignored for all other types (the disk size
              of other types is determined by the backing files, devies, etc.)
              If not given qemu-img defaults are used.
            '';
            default = null;
        };
        unit = mkOption{
          type = enum ["K" "M" "G" "T"];
          default = null;
          description = ''
            Only used if disk.type = "nix".
            The unit for the disk size for the image generated from the given nix file
            If not given qemu-img defaults are used.
        '';
        };
      };

    # volume
      # The underlying disk source is represented by attributes pool and volume. Attribute pool specifies the name of the storage pool (managed by libvirt) where the disk source resides. Attribute volume specifies the name of storage volume (managed by libvirt) used as the disk source. The value for the volume attribute will be the output from the "Name" column of a virsh vol-list [pool-name] command.
    
    # TODO source.nvme
    
      target = mkOption{
        type = types.str;
        example = "vda";
        description = ''
          The target element controls the bus / device under which the disk is exposed 
          to the guest OS. The dev attribute indicates the "logical" device name. The 
          actual device name specified is not guaranteed to map to the device name in 
          the guest OS. Treat it as a device ordering hint. The bus type is inferred from the style of the device name (e.g. a device named 'sda' will typically be exported using a SCSI bus).
        '';
      };

      readOnly = mkOption{
        type = types.bool;
        description = ''
          If present, this indicates the device cannot be modified by the guest.
          For now, this is the default for disks with attribute device='cdrom'.
          '';
        default = false;
      };

    transient = mkOption{
        type = types.bool;
        description = ''
          If present, this indicates that changes to the device contents should be reverted automatically when the guest exits. With some hypervisors, marking a disk transient prevents the domain from participating in migration, snapshots, or blockjobs. Only supported in vmx hypervisor (Since 0.9.5) and qemu hypervisor (Since 6.9.0).
          '';
        default = false;
      };
    };
  };

  xml = {lib, domain_name, disks, ...}: with lib;
    # [xml1 xml2 ...] -> xml1 + xml2 + ...
    concatStrings(
      # {name1 = xml1; name2 = xml2; ...} -> [xml1 xml2 ...]
      builtins.attrValues(
        # {name1 = disk1; name2 = disk2; ...} -> {name1 = xml1; name2 = xml2; ...}
        attrsets.mapAttrs(disk_name: 
          # disk -> xml
          disk: let
            disk_type = if disk.type == "nix" then "file" else disk.type;
            source_type = 
              if disk.type == "block" then "dev" else # block devices use "dev" as source
              if disk.type == "nix" then "file" else
              disk.type; # for the other types "type" and "source" are identical
            final_path = if disk.type == "nix" then 
                "var/lib/libvirt/images/${domain_name}-${disk_name}.qcow2"
              else 
                builtins.toString(disk.path);
          in ''
            <disk type="${disk_type}" device="${disk.device}">
              <source ${source_type}="${final_path}"/> 
              <driver name="${disk.driver.name}" type="${disk.driver.type}"/>
              <target dev="${disk.target}" bus="virtio"/>
              ${if disk.readOnly then "<readonly/>" else ""}
              ${if disk.transient then "<transient/>" else ""}
            </disk>
            ''
            )disks));
}