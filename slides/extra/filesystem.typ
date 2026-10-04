#import "/src/slides.typ": *


#slide[
  == File System

  - What is the file system and why do we need it?
  - What is a file and what is a folder?

    #align(center)[
    #image("../01_intro/img/os/abstractions.pdf", height: 80%)
    ]
]


#slide[
  = What is a file system? #text(size: 10pt, weight: "regular")[\ _organizing blocks of data_]
]

#slide[
  == Bibliography
  for this section

  + *Brian Ward*, _How LINUX Works_, 3#super[rd] Edition, No Starch Press, 2021
    - Chapter 4 - _Disks and Filesystems_
      - Sections 4.1 and 4.2
]

#slide[
  == How disk drives work
  Storage devices read and write blocks of data (512 B).

  #align(center)[#image("img/filesystem/disk_drive.pdf", width: 75%)]

  #reveal-code(lines:(1,2), after: gray, start: 2, full: false)[```rust
  fn read(block: usize) -> Result<[u8; 512], DiskError>; // read a block
  fn write(block: usize, data: [u8; 512]) -> Result<(), DiskError>; // write a block
  ```]

  #only(2)[Reads a block and returns either 512 bytes of data or an error.]
  #only(3)[Writes a block of data and returns nothing or an error.]
]

#slide[
  == How do you store data?

  #align(center)[#image("img/filesystem/block_store.pdf", width: 70%)]

  The 👨‍💻 user or developer has to remember a list of blocks in order.
]

#slide[
  == What is a file system?
  Organizes blocks into 📄 files and 📁 folders.

  #only(3)[
  #align(center)[#image("img/filesystem/file_system.pdf", width: 75%)]
  ]

  #only(1)[

  #align(center)[#image("img/filesystem/file_system_index.pdf", width: 75%)]
  ]


  #only(2)[
  #align(center)[#image("img/filesystem/file_system_data.pdf", width: 75%)]
  ]

  Splits the blocks in two parts:
  #item-by-item()[
  - 📋 _metadata_ - stores the blocks that contain the _list of blocks_ of the files and folders (10%)
  - 🗂️ _data_ - stores the blocks with the actual data (90%)
  ]
]

#slide[
  == File System Types

  #counter(footnote).update(0);

  Each operating system has _its own file system_

  #let fuse_footnote = footnote[*F*\ile *S*\ystem in *Us*\erspace - driver that allows writing a file system as a normal application];

  #uncover("2-")[
    #table(
      columns: (auto, auto, auto),
      table.header([OS], [Native File System(s)], [3#super[rd] Party]),
      [Windows], [`NTFS`, `FAT`], [-],
      [macOS],
      [`APFS`, `HFS+`, `NTFS`#footnote[Read Only Support], `FAT`, `macFUSE`#fuse_footnote],
      [`NTFS`],

      [Linux], [`ext4`, `OpenZFS`, `btrfs`, `NFS`, `FAT`, `fuse` #super[2]], [`NTFS`, `APFS`],
    )
  ]

  #uncover("3-")[⚠️ One file system per disk drive!]

  #uncover("4-")[🤔 What if we want more than one operating system on a disk drive?]

]

#slide[
  == Partitions
  Allow multiple file systems on the same disk drive

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1.5em)[
    - there has to be *at least one* partition
    - partitions do not have to be equal in size
    - each partition allows *one file system*

    #uncover(2)[
      Two partitioning systems
      - Master Boot Record - `MBR`
        - legacy (`BIOS`)
        - ⚠️ 4 partitions / 2 TB
      - *GUID Partition Table* - `GPT`
        - modern (`UEFI`)
    ]
  ][
    #align(center)[#image("img/filesystem/partitions.pdf", width: 95%)]
  ]
]

#slide[
  == Formatting
  Initializing a file system (index) on a partition

  #toolbox.side-by-side(columns: (1fr, 2fr), gutter: 1.5em)[
    - split the partition in two
      - _metadata_
      - _data_
    - write the _file index_ to the _metadata_
    - usually *does not delete any data* blocks

    💡 uses around 10% of disk space to store the _metadata_
  ][
    #align(center)[#image("img/filesystem/file_systems.pdf", width: 95%)]
  ]
]

#slide[
  == File System Actions

  + #uncover("1-")[*Partition* - split the drive space into non overlapping parts]
  + #uncover("2-")[
      *Format* - write the _file index_ to one of the partitions
      - ⚠️ partitions have to be formatted to be used
      - 💡 lose around 10% of disk space
    ]
  + #uncover("3-")[
      *Mount* - ask the operating system to display the partition
      - Windows: usually as a drive letter (`C:` `D:` ...)
      - POSIX: *replace a folder with the contents of the partition*
    ]

  #align(center)[#image("img/filesystem/fs_actions.pdf", width: 100%)]
]
