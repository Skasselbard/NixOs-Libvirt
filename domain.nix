{
  domain_options = {lib, types, ...}: with lib; with types;{
    options = {
      cpu.amount = mkOption{
         type= ints.positive;
         description = ''
           The maximum allocation of vcpus for the guest at boot time.
         '';
      };
      memory = {
        amount = mkOption{
          type= ints.positive;
          description = ''
            The maximum allocation of memory for the guest at boot time. The memory 
            allocation includes possible additional memory devices specified at start 
            or hotplugged later.
          '';
        };
        unit = mkOption{
          type = enum ["b" "bytes" "KB" "k" "KiB" "MB" "M" "MiB" "GB" "G""GiB" "TB" "T" "TiB"];
          default = "KiB";
          description = ''
            Defaults to "KiB" (kibibytes, 210 or blocks of 1024 bytes).
            Valid units are "b" or "bytes" for bytes, "KB" for kilobytes
            (103 or 1,000 bytes), "k" or "KiB" for kibibytes (1024 bytes), "MB" for 
            megabytes (106 or 1,000,000 bytes), "M" or "MiB" for mebibytes 
            (220 or 1,048,576 bytes), "GB" for gigabytes (109 or 1,000,000,000 bytes), 
            "G" or "GiB" for gibibytes (230 or 1,073,741,824 bytes), "TB" for terabytes 
            (1012 or 1,000,000,000,000 bytes), or "T" or "TiB" for tebibytes 
            (240 or 1,099,511,627,776 bytes). However, the value will be rounded up to 
            the nearest kibibyte by libvirt, and may be further rounded to the 
            granularity supported by the hypervisor. Some hypervisors also enforce a 
            minimum, such as 4000KiB. 
          '';
        };
      };
      enableVnc = mkEnableOption{
        description = "Adds a VNC interface for a virtual monitor";
      };
      disks = mkOption{
        type = attrsOf (submodule ((import ./disk.nix).disk_options{inherit lib types;}));
        description = "A set of disk definitions";
      };
    };
  };

       # {name1 = {memory1, ...}; name2 = {memory2, ...}; ...} -> {name1 = {xml1, memory1; ...}; name2 = {memory2; xml2; ...}; ...}
    gen_domain_xml = {lib, domains}: with lib; attrsets.mapAttrs(name: 
         # domain -> xml
         domain: with domain;{
           inherit memory disks cpu enableVnc;
           xml = ''
             <domain type="kvm">
               <uuid>UUID</uuid>
               <name>${name}</name>
               <os><type>hvm</type></os>
               <vcpu placement="static">${builtins.toString(cpu.amount)}</vcpu>
               <memory unit="${memory.unit}">${builtins.toString(memory.amount)}</memory>";
               <devices>
                 <interface type="bridge">
                   <source bridge="br0"/>
                   <model type="virtio"/>
                   <address type="pci" bus="0x01" slot="0x01"/>
                 </interface>
                 <input type="keyboard" bus="usb"/>
                 ${if enableVnc then ''<graphics type="vnc" autoport="yes"/>'' else ""}
                 ${(import ./disk.nix).xml{inherit lib disks; domain_name = name;}}
                 <rng model="virtio">
                    <backend model="random">/dev/urandom</backend>
                 </rng>
               </devices>
               <features>
                 <acpi/>
               </features>
             </domain>
           '';
           }
       )domains;
}