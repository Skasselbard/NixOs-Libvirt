{
    imports = [
      ../../common/vm_host.nix
    ];

    # Options from common/virtual_machines/network.nix
    ip = "192.168.1.12"; 
    hostname = "LillyLeaf";
    # The interface is determined by the pci address givin in the libvirt config
    interface = "ens1";

    # The ssh key from the host is mounted in the vm_host.nix config.
    # So we can use it directly here
    sshKey = builtins.readFile(
      builtins.head (builtins.filter builtins.pathExists [ "/root/.ssh/authorized_keys" ]));
}