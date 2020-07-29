pts-windows-nt-qemu: install and run Windows NT in QEMU on Linux
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
pts-windows-nt-qemu is a set of scripts for Linux to make Windows NT (3.1,
3.5, 3.51 and 4.0) installation and usage easier. You will need the original
Windows NT installer (floppy images or CD .iso image).

How to use:

1. Install QEMU, Mtools and unzip on your Linux host system.
   Example command for Debian 10:

     $ sudo apt-get install qemu-system-x86 mtools unzip

   If you have CD .iso image for Windows NT 3.x, install 7-Zip:

     $ sudo apt-get install p7zip-full

2. Get the most recent pts-windows-nt-qemu:

     $ wget -O pts-windows-nt-qemu-master.zip https://github.com/pts/pts-windows-nt-qemu/archive/master.zip
     $ unzip pts-windows-nt-qemu-master.zip
     $ cd pts-windows-nt-qemu

3. Get install media (floppy images or CD .iso image) for your operating
   system:

   * Windows NT 3.1: floppy images (*Disk*.img) or CD .iso image
   * Windows NT 3.5, 3.51 or 4.0: CD .iso image

4. For Windows NT 3.x with CD .iso image only: Extract the I386 directory in
   the CD .iso image (to within the pts-windows-nt-qemu directory), example:

     $ 7z x nt35.iso I386

5. For floppy images only: Copy the floppy images (*Disk*.img) to the
   appropriate nt*.cd directory within the pts-windows-nt-qemu directory,
   example:

     $ mkdir nt31.cd
     $ cp .../*Disk*.img nt31.cd/

6. Start QEMU by running the appropriate shell script:

     $ ./nt31.sh   # Windows NT 3.1
     $ ./nt35.sh   # Windows NT 3.5
     $ ./nt351.sh  # Windows NT 3.51
     $ ./nt40.sh   # Windows NT 4.0

   Upon first run, this will start installation (setup) within the QEMU
   virtual machine. Keep choosing the defaults unless a screenshot indicates
   otherwise. (See screenshots in the screenshot.nt* directory.)

   If you want networking, you need to install the AMD PCnet Ethernet card
   driver in the virtual machine. The screenshots show you how to do it
   during setup.

7. You can delete the nt*.cd directory now (and also the CD .iso files), you
   won't need them for subsequent runs.

8. You may want to disable swapping (page file) in the Control Panel / System
   after the first boot after setup. This will speed up the VM.

9. Optionally, if you want to try TCP/IP networking (on Windows NT 3.5 or
   later), don't try ping (because QEMU user networking doesn't return ICMP
   echo replies), but try this command instead: telnet github.com 22; on
   success, it prints a line starting with SSH-2.0- .

To copy small files between the Windows NT and the host, use floppy images:

* Use `./nt40.sh format-floppy' (or the corresponding other nt*.sh script) to
  create an empty floppy.img file of maximum size.

* Before starting the virtual machine, copy files to the image:

    $ mtools -c mcopy -i floppy.img MYFILE ::

* Start the virtual machine as usual, e.g. `./nt40.sh'.

* Within the virtual machine, use the A: drive to read and write files.

* After a few seconds of writing them, files automatically show up in the
  host, copy them like this:

    $ mtools -c mcopy -i floppy.img ::MYFILE ./

* To make files show up in the virtual machine without rebooting the virtual
  machine, first copy the files to floppy.img using mcopy (as above), then
  in the monitor tab of QEMU (Ctrl-Alt-<2>), run this command (without the
  (qemu) prefix):

    (qemu) change floppy0 floppy.img

* There is a default limit of 24 files in the root directory of the floppy.img.
  To create more files, create a directory, and copy the files there:

    $ mtools -c mmd -i floppy.img ::MYDIR
    $ mtools -c mcopy -i floppy.img MY* ::MYDIR/

Feature matrix (without any service packs or updates):

  Windows NT version            3.1   3.5   3.51   4.0
  -------------------------------------------------------
  maximum floppy size (KiB)     2880  4320  4320   4320
  NTFS filesystem               yes   yes   yes    yes
  FAT12 and FAT16 filesystems   yes   yes   yes    yes
  FAT32 filesystem              --    --    --     --
  long filenames on FAT         --    yes   yes    yes
  can run subsystem 4.0 .exe    --    yes   yes    yes
  TCP/IP networking             --    yes   yes    yes
  AMD PCnet driver built in     --    --    yes    yes
  installer can boot from CD    --    --    --     yes
  software shutdown with ACPI   --    --    --     --

What makes it complicated to install Windows NT within QEMU:

* The installer for Windows NT 3.x can't boot from CD. The recommended way
  is creating and using boot floppies. This is doable but inconvenient in
  QEMU. pts-windows-nt-qemu makes it convenient by preparing a bootable
  FAT16 filesystem (using Mtools) onto the HDD image, copying the required
  installer files (i.e. the entire I386 directory on the CD .iso image), and
  booting the blue text-mode installer (setup) directly from the HDD image.

* Windows NT 3.1 and 3.5 doesn't have a driver for an Ethernet network card
  supported by QEMU on the host side. pts-windows-nt-qemu makes it
  convenient by providing a driver for the AMD PCnet Ethernet card, and
  indicating in the screenshots how to add the driver during setup.

* Windows NT doesn't work with modern CPUs. pts-windows-nt-qemu solves this
  by specifying a working QEMU CPU flag (`-cpu 486' or `-cpu pentium').

* Windows NT doesn't work with too large disks. pts-windows-nt-qemu solves
  this by preparing a HDD image of size 140 MiB (small enough) with a FAT16
  filesystem, for maximum compatibility.

TODO(pts): Provide instructions for copying files between the host Linux and
the guest Windows NT system.

__END__
