System-On-Chip template based on Rocket-chip (RISC-V ISA). VHDL implementation.
=====================

This repository provides open source System-on-Chip implementation based on
64-bits CPU "Rocket-chip" distributed under BSD license. SOC source files
either include general set of peripheries, FPGA CADs projects files, own
implementation of the Windows/Linux debugger and several examples that help
to run your firmware on almost any FPGA boards.
Satellite Navigation (GPS/GLONASS/Galileo) modules were stubbed in this
repository and can be requested on
[gnss-sensor.com](http://www.gnss-sensor.com).


## What is Rocket-chip and [RISC-V ISA](http://www.riscv.org)?

RISC-V (pronounced "risk-five") is a new instruction set architecture (ISA)
that was originally designed to support computer architecture research and
education and is now set become a standard open architecture for industry
implementations under the governance of the RISC-V Foundation. RISC-V was
originally developed in the Computer Science Division of the EECS Department
at the University of California, Berkeley.

Parameterized generator of the Rocket-chip can be found here:
[https://github.com/ucb-bar](https://github.com/ucb-bar)

## System-on-Chip structure and performance

![SOC top](rocket_soc/docs/pics/soc_top_v5.png)

Performance analysis is based on
[**Dhrystone v2.1. benchmark**](http://fossies.org/linux/privat/old/dhrystone-2.1.tar.gz/)
that is very compact and entirely ported into Zephyr shell example.
You can run it yourself and verify results (see below).

**RISC-V Instruction simulator** - always one instruction per clock.  
**FPGA SOC based on "Rocket" CPU** - single core/single issue 64-bits CPU
with disabled L1toL2 interconnect (Verilog generated from Scala sources).  
**FPGA SOC based on "River" CPU** - single core/single issue 64-bits CPU is my own
implementation of RISC-V ISA (VHDL with SystemC as reference).  


Target | usec per 1 dhry | Dhrystone per sec | MHz,max | FPU | OS
-------|-----------------|-------------------|---------|-----|------
RISC-V simulator v3.1       | 12.0 | **77257.0** | -   | No  | Zephyr 1.3
FPGA SoC with "Rocket" v3.1 | 28.0 | **34964.0** | 60  | No  | Zephyr 1.3
FPGA SoC with "Rocket" v4.0 | 40.7 | **24038.0** | 60<sup>1</sup>  | Yes | Zephyr 1.5
FPGA SoC with "River " v4.0 | 28.0 | **35259.0** | 60<sup>1</sup>  | No | Zephyr 1.5

<sup>1</sup> - Actual SoC frequency is 40 MHz (to meet FPU constrains) but
Dhrystone benchmark uses constant 60 MHz and high precision counter (in clock cycles)
to compute results.

Access to all memory banks and peripheries in the same clock domain is always
one clock in this SOC (without wait-states). So, this benchmark 
result (**Dhrystone per seconds**) shows performance of the CPU with integer 
instructions and degradation of the CPI relative ideal (simulation) case.

I'll continue to track changes of Dhrystone results in future 
"Rocket" chip versions. But since v1.5 "RIVER" is the default CPU 
(VHDL configuration parameter *CFG_COMMON_RIVER_CPU_ENABLE*=true).


## Repository structure

This repository consists of three sub-projects each in own subfolder:

- **rocket_soc** is the folder with VHDL/Verilog sources of the SOC
  including synthesizable processors *"Rocket"* and *"River"* and peripheries. 
  Source code is portable on almost any FPGA is due to the fact that
  technology dependant modules (like *PLL*, *IO-buffers* 
  etc) instantiated inside of "virtual" components 
  in a similar to Gailser's *[GRLIB](www.gailser.com)* way.  
  Full SOC design without FPU occupies less than 5 % of FPGA resources (Virtex6). 
  *"Rocket-chip"* CPU itself is the modern **64-bits processor 
  with L1-cache, branch-predictor, MMU and virtualization support**.  
  This sub-project also contains:
    * *fw*: directory with the bootloader and FW examples.
    * *fw_images*: directory with the ROM images in HEX-format.
    * *prj*: project files for different CADs (Xilinx ISE, ModelSim).
    * *tb*: VHDL testbech of the full system and utilities.
- **zephyr** is the ported (by me) on RISC-V 64-bits operation system.
  Information about this Real-Time Operation System for Internet of
  Things Devices provided by [Zephyr Project](https://www.zephyrproject.org/).
  Early support for the Zephyr Project includes Intel Corporation,
  NXP Semiconductors N.V., Synopsys, Inc. and UbiquiOS Technology Limited.
- **debugger**. The last piece of the ready-to-use open HW/SW system is
  [Software Debugger (C++)](http://sergeykhbr.github.io/riscv_vhdl/dbg_link.html)
  with the system simulator available as a plug-in (either as GUI
  or any other extension). Debugger interacts with the target (FPGA or
  Simulator) via [Ethernet](http://sergeykhbr.github.io/riscv_vhdl/eth_link.html)
  using EDCL protocol over UDP. To provide this functionality SOC includes
  [**10/100 Ethernet MAC with EDCL**](http://sergeykhbr.github.io/riscv_vhdl/eth_link.html)
  and [**Debug Support Unit (DSU)**](http://sergeykhbr.github.io/riscv_vhdl/dsu_link.html)
  devices on AMBA AXI4 bus.
- **RISC-V "River" core**. It's my own implementation of RISC-V ISA that is ideal
  for embedded application with active usage of 64-bits computations
  (DSP for Satellite Navigation). I've specified the following principles for myself:
    1. Unified Verification Methodology (UVM)
        - */debugger/cpu_fnc_plugin*  - Functional RISC-V CPU model.
        - */debugger/cpu_sysc_plugin* - Precise SystemC RIVER CPU model.
        - */rocket_soc/riverlib*      - RIVER VHDL sources with VCD-stimulus from SystemC.
    2. Advanced debugging features: bus tracing, pipeline statistic (like CPI) in real-time on HW level etc.
    3. Integration with GUI from the very beginning.
  I hope to develop the most friendly synthesizable processor for HW and SW developers
  and provide debugging tools of professional quality.

## Step-by-step tutorial of how to run Zephyr-OS on FPGA board with synthesizable RISC-V processor.

To run provided **shell** application as on the animated picture bellow, we should do
several steps:

1. Setup GCC toolchain
2. Build Zephyr elf-file (shell example) and generate HEX-image to
   initialize ROM so that our FPGA board was ready to use without additional
   reprogram.
3. Build FPGA bitfile from VHDL/Verilog sources and program FPGA.
4. Install CP210x USB to UART bridge driver (if not installed yet) and
   connect to serial port of the SOC.
5. Final result should look like this:

![Zephyr demo](rocket_soc/docs/pics/zephyr_demo.gif)

### 1. Setup GCC toolchain

  You can find step-by-step instruction of how to build your own
toolchain on [riscv.org](http://riscv.org/software-tools/). If you would like
to use pre-build GCC binary files and libraries you can download it here:

   [Ubuntu GNU GCC 6.1.0 toolchain RV64D (207MB)](http://www.gnss-sensor.com/index.php?LinkID=1018)  
   [Ubuntu GNU GCC 6.1.0 toolchain RV64IMA (204MB)](http://www.gnss-sensor.com/index.php?LinkID=1017)  

   [(obsolete) Ubuntu GNU GCC 5.1.0 toolchain RV64IMA (256MB)](http://www.gnss-sensor.com/index.php?LinkID=1013)

  GCC 5.1.0 is the legacy version for *riscv_vhdl* with tag **v3.1** or older.  
**RV64IMA** build doesn't use hardware FPU (*--soft-float*). **RV64D** build 
requires FPU co-processor (*--hard-float*).

  Just after you download the toolchain unpack it and set environment variable
as follows:

    $ tar -xzvf gnu-toolchain-rv64ima.tar.gz gnu-toolchain-rv64ima
    $ export PATH=/home/your_path/gnu-toolchain-rv64ima/bin:$PATH

If you would like to generate hex-file and use it for ROM initialization you can use
*'elf2hex'* and *'libfesvr.so'* library from the GNU toolchain but I suggest to use my version
of such tool *'elf2raw64'*. I've put this binary into pre-built GCC archive 'gnu_toolchain-rv64/bin'. 
If *elf2raw64* conflicts with installed LIBC version re-build it from *fw/elf2raw64/makefiles*
directory.

### 2. Build Zephyr OS

Download and patch Zephyr kernel version 1.5.0:

    $ mkdir zephyr_150
    $ cd zephyr_150
    $ git clone https://gerrit.zephyrproject.org/r/zephyr
    $ cd zephyr
    $ git checkout tags/v1.5.0
    $ cp ../../riscv_vhdl/zephyr/v1.5.0-branch.diff .
    $ git apply v1.5.0-branch.diff

Build elf-file:

    $ export ZEPHYR_BASE=/home/zephyr_150/zephyr
    $ cd zephyr/samples/shell
    $ make ARCH=riscv64 CROSS_COMPILE=/home/your_path/gnu-toolchain-rv64ima/bin/riscv64-unknown-elf- BOARD=riscv_gnss 2>&1 | tee _err.log

Create HEX-image for ROM initialization. I use own analog of the *elf2raw*
utility named as *elf2raw64*. You can find it in GNU tools archive.

    $ elf2raw64 outdir/zephyr.elf -h -f 262144 -l 8 -o fwimage.hex

Flags:

    -h        -- specify HEX format of the output file.
    -f 262144 -- specify total ROM size in bytes.
    -l 8      -- specify number of bytes in one line (AXI databus width). Default is 16.

Copy *fwimage.hex* to rocket_soc subdirectory

    $ cp fwimage.hex ../../../rocket_soc/fw_images

### 3. Build FPGA bitfile for ML605 board (Virtex6)

- Open project file for Xilinx ISE14.7 *prj/ml605/rocket_soc.xise*.
- Edit configuration constants in file **work/config_common.vhd** if needed.
  (Skip this step by default).
- Generate bit-file and load it into FPGA.

### 4. Connecting to serial port

Usually I use special client to interact with target but in general case
let's use standard Ubuntu utility 'screen'

    $ sudo apt-get install screen
    $ sudo screen /dev/ttyUSB0 115200

Use button "*Center*" to reset FPGA system and reprint initial messages:

```
    Boot . . .OK
    Zephyr version 1.5.0
    shell>
```

Our system is ready to use. Shell command **pnp** prints SOC HW information,
command **dhry** runs Dhrystone 2.1 benchmark.
To end the session, use Ctrl-A, Shift-K


## Debugger with GUI

Instruction of how to connect FPGA board via
[Ethernet](http://sergeykhbr.github.io/riscv_vhdl/eth_link.html)
your can find here. Simulation and Hardware targets use identical
EDCL over UDP interface so that Debugger can work with any of them
using the same set of commands. **Debugger doesn't implement any specific
interface for the simulation.**

To build Debugger with GUI download and install the latest QT-libraries and
set environment variable QT_PATH as follow:

    $ export QT_PATH=/home/you_work_dir/Qt5.7.0/5.7/gcc_64

Build debugger:

    $ cd .../riscv_vhdl/debugger/makefiles
    $ make

Run application as follow and you should see something like on image below:

    $ cd ../linuxbuild/bin
    $ ./run_gui_sim.sh

![Debugger demo](rocket_soc/docs/pics/debugger_demo.gif)    

You can either run application as:

    $ ./appdbg64g.exe -sim -gui -nocfg

where:  
    *-sim*   Use SoC Simulator not a Real Hardware (FPGA)  
    *-gui*   Use GUI instead of console mode  
    *-nocfg* Use default config instead of *config.json* file  

SOC simulator includes not only CPU emulator but also any number of
custom peripheries, including GNSS engine or whatever.
To get more information see
[debugger's description](http://sergeykhbr.github.io/riscv_vhdl/dbg_link.html).


## Simulation with ModelSim

1. Open project file *prj/modelsim/rocket.mpf*.
2. Compile project files.
3. If you get an errors for all files remove and re-create the following
   libraries in ModelSim library view:
     * techmap
     * ambalib
     * commonlib
     * rocketlib
     * gnsslib
     * work (was created by default)
4. Use *work/tb/rocket_soc_tb.vhd* to run simulation.
5. Testbench allows to check the following things:
     * LEDs switching
     * UART output
     * Interrupt controller
     * UDP/EDCL transaction via Ethernet
     * Access to CSR via Ethernet + DSU.
     * and other.


## Build and run 'Hello World' example.

Build example:

    $ cd /your_git_path/rocket_soc/fw/helloworld/makefiles
    $ make

Run debugger console:

    $ ./your_git_path/debugger/linuxbuild/bin/appdbg64g.exe -sim -gui -nocfg

Load elf-file via Ethernet using debugger console:

    #riscv loadelf bin/helloworld

You should see something like:

```
    riscv# loadelf e:/helloworld
    [loader0]: Loading '.text' section
    [loader0]: Loading '.eh_frame' section
    [loader0]: Loading '.rodata.str1.8' section
    [loader0]: Loading '.rodata' section
    [loader0]: Loading '.data' section
    [loader0]: Loading '.sdata' section
    [loader0]: Loading '.sbss' section
    [loader0]: Loading '.bss' section
    [loader0]: Loaded: 42912 B
```

Just after image loading finished debugger clears reset CPU signal and starts
execution. This example prints only once UART message *'Hello World - 1'*,
so if you'd like to repeat test reload image using **loadelf** command.

Now you can also generate HEX-file for ROM initialization to do that
see other example with **bootrom** implementation

    $ cd rocket_soc/fw/boot/makefiles
    $ make
    $ cd ../linuxbuild/bin

Opened directory contains the following files:
- _bootimage_       - elf-file (not used by SOC).
- _bootimage.dump_  - disassembled file for the verification.
- *_bootimage.hex_* - HEX-file for the Boot ROM intialization.

You can also check *bootimage.hex* and memory dump for consistence:

    #riscv dump 0 8192 dump.hex hex

I hope your also have run firmware on RISC-V system successfully.

My usual FPGA setup is ML605 board and debugger that is running on Windows 7
from Visual Studio project, so other target configurations (linux + KC705)
could contain errors that are fixing with a small delay. Let me know if see one.


## Versions History

### Implemented functionality (v4.0)

- Support new revision of User-Level ISA Spec. 2.1 and Privileged spec. 1.9.
- FW will be binary incompatible with the previous Rocket-chip CPU (changed CSR's 
indexes, instruction ERET removed, new set of instructions xRET was added etc).
- GCC versions (5.x) becomes obsolete.
- FPU enabled by default and pre-built GCC 6.x with --hard-float provided.
- HostIO bus removed.
- HW Debug capability significantly affetcted by new DebugUnit, but Simulation
significantly improved.
- Updated bootloader and FW will become available soon.

### Implemented functionality (v3.1)

To get branch *v3.1* use the following git command:

    $ git clone -b v3.1 https://github.com/sergeykhbr/riscv_vhdl.git

This is the last revision of the RISC-V SOC based on ISA version 1.9.
All afterwards updates will be **binary incompatible** with this tag.
Tag v3.1 adds:

- New Zephyr Kernel with the shell autocompletion.
- Significantly updated GUI of the debugger.

**Use tag v3.1 and GCC 5.1.0 instead of latest revision while release v4.0
won't ready. GCC 6.1.0 and 5.1.0 are binary incompatible either as SoC itself!**


### Implemented functionality (v3.0)

To get branch *v3.0* use the following git command:

    $ git clone -b v3.0 https://github.com/sergeykhbr/riscv_vhdl.git

- Ported open source Real-Time Operation System for Internet of Things
  Devices provided by [Zephyr Project](https://www.zephyrproject.org/).
- Benchmark *Dhrystone v2.1* run on FPGA and Simulator with published results.
- Testmode removed. *'gnsslib'* fully disabled.
- Graphical User Interface (GUI) for the debugger based on QT-libraries
  with significantly increasing of the debugger functionality.

### Implemented functionality (v2.0)

To get branch *v2.0* use the following git command:

    $ git clone -b v2.0 https://github.com/sergeykhbr/riscv_vhdl.git

This release add to following features to *v1.0*:

- [**Debug Support Unit**](http://sergeykhbr.github.io/riscv_vhdl/dsu_link.html)
  (DSU) for the access to all CPU registers (CSRs).
- [**10/100 Ethernet MAC with EDCL**](http://sergeykhbr.github.io/riscv_vhdl/eth_link.html)
  that allows to debug processor from the
  reset vector redirecting UDP requests directly on system bus.
- GNSS engine and RF-mezzanine card support.
- **Test Mode** (DIP[0]=1) that allows to use SOC with or without
  *RF-mezzanine card*.
- Master/Slave AMBA AXI4 interface refactoring.
- [**Debugger Software (C++)**](http://sergeykhbr.github.io/riscv_vhdl/dbg_link.html)
  for Windows and Linux with built-in simulator and plugins support.
- Portable asynchronous FIFO implementation allowing to connect modules to the
  System BUS from a separate clock domains (ADC clock domain):
- A lot of system optimizations.


### Implemented functionality (v1.0)

The initial *v1.0* release provides base SOC functionality with minimal
set of peripheries. To get this version use:

    $ git clone -b v1.0 https://github.com/sergeykhbr/riscv_vhdl.git

- Proof-of-concept VHDL SOC based on Verilog generated core *"Rocket-chip"*.
- Peripheries with AMBA AXI4 interfaces: GPIO, LEDs, UART, IRQ controller etc.
- Plug'n-Play support.
- Configuration and constraint files for ML605 (Virtex6) and KC705 (Kintex7)
  FPGA boards.
- Bit-files for ML605 and KC705 boards.
- Pre-built ROM images with the BootLoader and FW-image. FW-image is copied
  into internal SRAM during boot-stage.
- *"Hello World"* example.


## Doxygen project documentation

[http://sergeykhbr.github.io/riscv_vhdl/](http://sergeykhbr.github.io/riscv_vhdl/)
