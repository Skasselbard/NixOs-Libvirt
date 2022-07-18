{
  # The mounts are important for auto configuration with systemd as defined in 'common/vm_host_base.nix

  # The root partition is where the disk from the genereated qcow image is mounted
  fileSystems."/".device = "/dev/disk/by-label/nixos";
  # I use '/etc/nixos' to mount the specialized configuration.
  # It seems to be a good place but I have not given it much thought
  # '/etc/nixos' is the place where the example root is mounted (with 'common' and 'hosts' as subfolder)
  # See the example readme for the deeper thoughts on the mounting structure.
  fileSystems."/etc/nixos".device = "/dev/vdb1";
  # Mount the specialized config at hosts/self.
  # This folder stays the same for all vms, while simultaniously its content can be different.
  # The content is defined in the libvirt.domains config of the host
  fileSystems."/etc/nixos/hosts/self" = {
    device = "/dev/vdc1";
    fsType = "vfat";
    # I think this is autonmatically detected, but we don't need to take the risk
    depends = ["etc/nixos"];
    # Mount with
    #   - read only: because the files are in the nix store of the host, which is
    #                read only anyway.
    #   - nofail: otherwise the vm does not boot.
    #             Probably because the folder does not exits at the necessary time.
    #             However, with nofail this partition is marked as not critical for
    #             booting, so the boot can finish.
    #             And the filesystem will still be mounted in the end.
    options = [ "ro" "nofail" ];
  };
  # Mount the ssh folder from the host in the guest so we can use the same keys to connect.
  # This step is optional and I am not sure if it is entirely safe.
  # But I can see no obvious risk and find this configuration quite convenient.
  fileSystems."/root/.ssh" = {
    device = "/dev/vdd1";
    fsType = "vfat";
    options = [ "ro" "nofail" ];
  };
}