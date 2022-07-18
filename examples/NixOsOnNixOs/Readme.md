# NixOs on NixOs

This example shows how to configure a NixOs host with a domain that runs itself NixOs.
I use this setup to configure a stable physical machine which runs volatile guests.
The host has a minimal configuration that should not change very often, but the VMs are free to change rapidly (because failures can be fixed remotely and are therefore are not as painful).

NixOS-Libvirt has options to automatically build a qcow image from a nix configuration for this use case.
The resulting image will be placed in the nix store.
Files in the nix store are read only, so the image can't be used directly by the VMs.
Instead, another qcow image will be created in ``/var/lib/libvirt/images`` that uses the store image as a backing file, only tracking the changes from the backing image.
An upside of this approach is that multiple VMs that are based on the same nix configuration will use the same backing image in the store, making the memory footprint of the setup smaller.
However, every change in the nix file results in a new store image which probably can crowd disk space very fast if you fiddle around with configurations.
So, keep that in mind ;D

## Auto-configuration of the NixOS VM during first boot

In this example I configured a VM so that it bootstraps itself from a common configuration to a specialized machine.
The configuration can be shared with other VMs as mentioned above.
I make the specialized configuration available in the guest by mounting some directories with the target configuration from the host in the VM.
The directories are exposed as disks in the VM and mounted to known locations as part of the common nix configuration.
During the start of the vm, a systemd service is started that runs nixos-rebuild with the mounted specialized configuration.  
> Fun Fact: I run ``nixos-rebuild boot [args]`` followed by a ``reboot`` instead of running ``nixos-rebuild switch`` directly because it officially fails (although a reboot actually uses the new configuration).
> The reason, as far as I understand it, is that a switch causes systemd to restart, which seems to kill the ``nixos-rebuild`` service on the way.
> A nice example of how to cut the branch you are sitting on :D

The nice thing of this setup is that you don't need access to the vm;
Not even a user login.
This means that you can configure access, including the network, separately per VM in the specialized configuration.
And all while doing nothing but wait (although this can be hard by itself ;) ).

## Bootstrapping a specialized configuration from a common base VM

I use a folder structure inspired by [Xe's Blog](https://xeiaso.net/blog/morph-setup-2021-04-25) in this example.
The folders will be mounted from the hosts nix store in the VM.
The paths are mounted in specific locations to keep relative paths consistent.
Here is what the paths and important files mean (some of this is redundant with Xe's Blog):
- Folders:
  - ``common`` -> base configuration that systems share
    - ``physical machines`` -> common configuration for libvirt host machines
    - ``virtual machines`` -> common configuration for libvirt guest machines (VMs)
  - ``hosts`` -> the final (specialized) configuration for both VMs and hosts
- Files:
  - ``common/default.nix``
    - common for all configurations (hosts and guests)
    - imports all submodules that are shared by all configurations
    - machines **should not** base their configuration on this file.
      Instead, use one of the following files.
  - ``common/physical_host.nix``
    - common for all physical hosts
    - imports ``common/default.nix`` and the default configuration from ``common/physical_machines``
    - this configuration is used for all machines that should create libvirt guests
  - ``common/vm_host_base.nix``
    - The base configuration for all VMs
    - part of the configuration is a systemd service that automatically reconfigures this machine to use the specialized configuration
  - ``common/vm_host.nix``
    - common for all virtual machines
    - imports ``default.nix`` and the default configuration from ``common/virtual_machines``
    - this configuration is used for all specialized configurations running in a VM

The libvirt configuration in the example host (``hosts/IAmRoot.nix``) for the vms defines four disks which are mounted in the vms according to ``common/virtual_machines/partitioning.nix``.
We use an important nix feature here to make sure that our configuration files are unambiguous (and get distributed with deployment tools like [NixOps](https://nixos.wiki/wiki/NixOps) and [Colmena](https://github.com/zhaofengli/colmena)).  
If we define a variable with a [path](https://nixos.org/manual/nix/stable/expressions/language-values.html), nix will copy the location in the nix store with all contained files.
If we later reference the variable with this path, we do not actually reference the path we configured, but actually reference the copied files in the nix store.
This is especially handy if we use one of the mentioned deployment tools, because we can be sure that locally referenced files get deployed to target machines.
And all relative paths below the path variable are preserved :D
These are the disks:

1. os:
   - This disk is generated from the given nix configuration.
   - The result is a qcow image placed in the nix store of the host
   - Another qcow image in ``var/lib/libvirt`` backed by the generated store image tracks all changes
   - It will be mounted as root partition
2. nixConfig:
   - This disk contains all files that are in this examples' folder with ``common`` and ``hosts`` as subfolders
   - It will be mounted at ``/etc/nixos``
3. selfConfig:
   - This disk contains the specialized configuration for this virtual machine in the ``hosts`` folder
   - It will be mounted at ``/etc/nixos/hosts/self`` inside the previously mounted file system (nixConfig)
   - We can configure this in the libvirt configuration while keeping the ``vm_hoist_base.nix`` untouched
   - This way we can have different content in the ``self`` folder over multiple VMs to bootstrap a specialized guest from a common nix configuration
4. ssh (optional):
   - This disk contains the ``/root/.ssh`` folder from the host
   - It will be mounted at ``/root/.ssh`` in the guest
   - This way we don't need to configure an ssh key for the vms and can reuse the hosts authorized keys

I can smell safety issues with the ssh mount, although I don't see an obvious problem.
I would want to access the VMs with the same sshKey as the host anyway.
Actually this even eliminates a possible publication of the ssh key configuration;
but I am not a security expert.
Feel free to skip this mount if you have doubts.

## Network

I want the VMs as part of my LAN (with static networking).
This is usually done by connecting the VMs to a network bridge on the Host.
The bridge has to be configured with an interface that is connected to the LAN
and the VM has to be configured to use the bridge.
