#import "/src/slides.typ": *

#slide[
  = Virtual Machine #text(size: 10pt, weight: "regular")[\ _run an OS within an application_]
]

#slide[
  == The Idea
  _run an operating system within an application_

  Why?
  - Debug operating systems
  - Run software that is not compatible with the OS your computer runs
  - Securely share a server

  Virtualization Software
  - #link("https://www.virtualbox.org/")[VirtualBox]
  - #link("https://www.vmware.com/")[VMWare]
  - #link("https://www.qemu.org/")[QEMU]
]

#slide[
  == Simulation / Emulation
  simulate all the hardware - very slow

  #align(center)[#image("img/vm/vmm_simulation.pdf", width: 55%)]

  QEMU
  - is able to simulate most of the available architectures
    - most used `x86`, `AMD64`, `arm`, `aarch64`, `powerpc`, `risc-v`
]

#slide[
  == Virtualization
  Use a part of the available hardware, emulates as if the system was running alone on the hardware

  #toolbox.side-by-side(columns: (6fr, 3fr), gutter: 1.5em)[
    #align(center)[#image("img/vm/vmm_emulation.pdf", width: 90%)]

    #item-by-item(start: 2)[
      - Requires VT-x (Intel), AMD-V (AMD) or VHE (ARM)
      - The guest OS has to be built for the same CPU architecture as the host OS
        - _Intel / AMD_ is x86_64 (`amd64`)
        - _Apple Silicon_ is ARM64 (`aarch64`)
    ]

  ][
#only("4,5")[

    === Hypervisors
      - #box[#image("img/vm/vmware.png", height: 6%)] VMWare
      - #box[#image("img/vm/virtualbox.svg", height: 6%)] VirtualBox
      - #box[#image("img/vm/qemu.png", height: 6%)] QEMU using `hyper-v`, `KVM` or _Hypervisor.framework_
    ]

  ]

  #only(5)[
    #quote(block: true)[Make sure you download a Linux version for `amd64` or `aarch64`]
  ]
]

#slide[
  == VirtualBox Machine Settings

  #align(center)[
    #image("img/vm/virtualbox_vm.png")
  ]
]
