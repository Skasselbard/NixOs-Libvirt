{
    # base this configuration on the one for physical hosts
    imports = [
      ../common/physical_host.nix
    ];

    # options defined in common/physical_machines/network.nix
    ip = "192.168.1.2"; 
    hostname = "IAmRoot";
    interface = "eno1";
    bridgename = "br0"; # The bridge to be used by vms to connect to the LAN directly
    # The partitions with these uuids have to exist. You have to create them first andimport them in ths configuration.
    boot-uuid = "ABCD-1234";
    root-uuid = "12345678-90ab-cdef-fedc-ba0987654321";

    # I have this line from some example from git, but forgot from where :(
    # You can add multiple public key files there if you have more than one 
    sshKey = builtins.readFile(
      builtins.head (builtins.filter builtins.pathExists [ ~/.ssh/id_rsa.pub ]));
    libvirt.domains = 
      # This is the path to the examples folder (the project root for our purposes).
      # Nix will copy the folder into the nix store so that the content is available 
      # even if you deploy the configuration with tools like NixOps or Colmena
      let modulesPath = ../.; in {
        # The name is used as VM-name and in the name for its systemd service
        LillyLeaf = {
          cpu.amount = 2; # two cores
          memory.amount = 4;
          memory.unit = "GiB";
          disks = {
            # The given nix configuration will be built into a qcow image and acts as a
            # backing file for the actual qcow image used for the vm.
            os = {
              type = "nix";
              path = "${modulesPath}/common/vm_host_base.nix";
              nix.size = 50;
              nix.unit = "G";
              target = "vda";
            };
            # The files defined above will be exposed as a disk to mount inside the vm
            nixConfig = {
              type = "dir";
              path = "${modulesPath}";
              driver.name = "qemu";
              # I didnt find the "fat" driver type in the libvirt xml docu.
              # But I saw it in some example and it actually works
              driver.type = "fat";
              # The target will be available in '/dev' in the guest.
              # We will use it to mount its file system in the 'vm_host_base.nix'
              target = "vdb";
              # Fat drives have to be read only though.
              # But since the files are stored in the nix store, they are read only anyway
              readOnly = true;
            };
            # The specialized configuration for for this specific guest
            selfConfig = {
              type = "dir";
              path = "${modulesPath}/hosts/LillyLeaf";
              driver.name = "qemu";
              driver.type = "fat";
              target = "vdc";
              readOnly = true;
            };
            # The hosts ssh path
            ssh = {
              type = "dir";
              path = "/root/.ssh/";
              driver.name = "qemu";
              driver.type = "fat";
              target = "vdd";
              readOnly = true;
            };
          };
          # Spice didn't work. Don't know why but VNC does... If you need it at all
          enableVnc = true;
        };
    };
}