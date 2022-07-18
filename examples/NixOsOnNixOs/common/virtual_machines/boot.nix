{ modulesPath, ... }:
{
  # A nix native module with some default settings for qemu guests
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader = {
    grub = {
      version = 2;
      device = "/dev/vda";
    };
    timeout = 0;
  };
  # I don't which modules are realy necessary (probably only the ones from the imported qemu-guest module) but I saw these often and tried to avoid annoying errors.
  boot.initrd.availableKernelModules = [ 
    "ata_piix"
    "uhci_hcd"
    "sr_mod"
  ];
}
