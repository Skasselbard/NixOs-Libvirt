# Nixos libvirt VM services

A module to create libvirt Domains (aka Virtual Machines) from a nix configuration for NixOS.

Inspired by the service setup from the [NixOS Wiki](https://nixos.wiki/wiki/NixOps/Virtualization).

I tried to make options from the [libvirt XML format](https://libvirt.org/format.html) available for NixOS.
My goal was to configure qemu/kvm virtual machines on a NixOS host with a simple configuration interface.
Where I could, I added options that are not relevant for my use case, but generally I do not intent to cover settings that I don't use.
I also don't check all cross dependencies between the settings.
Libvirt will complain if settings are incompatible (see the [Debugging](##Debugging) section).
However, I will accept contributions if they are well-structured and documented (an example which shows the usage of the contributed options would also be appreciated).

## Every VM is a service

I followed the idea from the [NixOS Wiki](https://nixos.wiki/wiki/NixOps/Virtualization) and expose every domain (VM) as a systemd service.
The configured VMs are defined and started with systemd and the definitions are removed if the corresponding service stops (including reboots).
You can still make changes to the VM in between (e.g. with [Virt-Manager](https://virt-manager.org/)) but don't expect changes to persist.

## Domains

[Libvirt Docs](https://libvirt.org/formatdomain.html)

### Implemented domain options

Prefix for all domain options is ``libvirt.domains.<name>``

- cpu.amount: positive integer
- memory 
  - amount: positive integer
  - unit: "b", "bytes", "KB", "k", "KiB", "MB", "M", "MiB", "GB", "G", "GiB", "TB", "T" or "TiB"
    - the unit of the memory amount as expected by libvirt
  - enableVnc: boolean
  - disks: disk names and their configuration closure
    - see the [disk options](###-Implemented-disk-options)

## Disks

Besides the options libvirt expects for disk configuration I added an option to define a disk from a nix configuration file.
If you use the disk type ``nix`` you can give a path to a configuration for a NixOs system.
This configuration will be compiled with [nixos-generate](https://github.com/nix-community/nixos-generators) to a qcow2 image by the [vm service](##-Every-VM-is-a-service).
The resulting image is placed in the nix-store on the libvirt host.
The store is read only, so the build image is used as a backing file for the "real" image, which is placed at ``/var/lib/libvirt/image``.
The backed file will only track the changes that are made from the original image.
This behaviour can come in handy if you have a base configuration for multiple VMs.
The backing image will be the same on all VMs, saving disk space in the process.
Check out my ``NixOs on NixOs example`` in the example folder to learn more.

However, I do not know how nix handles the generated images.
First I don't think unused images get deleted automatically, so if you test out a lot of base configurations you might crowd your disk memory.
Also, I'm not sure if the generated image is removed by the nix garbage collection, but if it is, it should be rebuilt if the vm service is restarted.
The backed images should be untouched by the whole process once they are created.
If you want to get rid of them, you have to delete them manually.
If you do, it is best to collect the backing image as well, because a regeneration will fail if the backing image still exists.

### Implemented disk options

[Libvirt Docs](https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms)

Disk options are part of domain configuration in  ``libvirt.domains.<domain_name>.disks.<disk_name>``

- type: "nix", "file", "block", "dir" or "volume"
- device: only "disk" is accepted currently
- driver
  - name: "qemu", "tap", "tap2", "phy", "file"
  - type: "aio", "raw", "bochs", "qcow2", "qed" or "fat"
- path: nix path
  - what is expected at the path is determined by the disk type
- nix
  - size: positive integer
    - target maximal size of the generated qcow image
  - unit: "K", "M", "G" or "T"
    - the unit of the given size as expected by ``qemu-img``

## Networks

[Libvirt Docs](https://libvirt.org/formatnetwork.html)

## Use Cases

Check out the ``examples`` folder for use cases.

## Debugging

Check the logs for the service from domain \<name\>:

```shell
journalctl -u libvirtd-domain-<name>.service
```
