{
  # generate a qcow2 disk image from a nix configuration file
  qcowFromNix = { disk_name, disk }: ''
    #!/bin/bash
    # make the script fail if any cmd returns nonzero
    set -e

    # build qcow image from nix. The last cmd line will be the store path.
    store_image=$(nixos-generate -f qcow -c ${disk.path} | tail -1)
    if [[ -n $store_image ]]; then 
      echo "nixos-generate failed and returned no path"
      exit 1
    fi

    # Get the hash from the store path to make the final image name unique.
    store_id=$(echo $store_image | cut -d/ -f4)
    image_name=/var/lib/libvirt/images/"$store_id"_${disk_name}.qcow2



    echo $store_image
    echo $store_id
    echo $image_name

    # The generated image is read only (since it is in the nix store).
    # So we create a new image that is backed by the store image
    if test -f "$image_name"; then
      echo "nix image already exists"
    else
      qemu-img create -f qcow2 -F qcow2 -b $store_image $image_name ${
        builtins.toString (disk.nix.size)
      }${disk.nix.unit}
      # recreate canonical soft link
    fi
      rm -f /var/lib/libvirt/images/${disk_name}.qcow2
      ln -s $image_name /var/lib/libvirt/images/${disk_name}.qcow2
  '';
  defineDomain = { pkgs, name, xml }: ''
    uuid="$(${pkgs.libvirt}/bin/virsh domuuid '${name}' || true)"
    ${pkgs.libvirt}/bin/virsh define <(sed "s/UUID/$uuid/" '${xml}')
    ${pkgs.libvirt}/bin/virsh start '${name}'
  '';
  stopDomain = { pkgs, name }: ''
    ${pkgs.libvirt}/bin/virsh shutdown '${name}'
    let "timeout = $(date +%s) + 10"
    while [ "$(${pkgs.libvirt}/bin/virsh list --name | grep --count '^${name}$')" -gt 0 ]; do
      if [ "$(date +%s)" -ge "$timeout" ]; then
        # Meh, we warned it...
        ${pkgs.libvirt}/bin/virsh destroy '${name}'
      else
        # The machine is still running, let's give it some time to shut down
        sleep 0.5
      fi
    done
  '';
}
