{ ... }:
{
  imports = [
    ./virtualisation
    ./partitioning.nix
    ./network.nix
  ];
  
  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    # You need some kernel modules for virtualization
    # These work for me but I claim the list neither exhaustive nor minimal.
    kernelModules = [ "kvm-amd" "kvm-intel" ];
    initrd.availableKernelModules = [
     "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"
    ];
  };
}