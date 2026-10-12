# aximem_ss Testbench

This testbench checks the AXI memory subsystem implemented in:

```text
rtl/mem_interface/aximem_ss.v
```

It runs a small set of AXI read/write transactions and reports whether the
module behaves as expected.

## What The Testbench Checks

The testbench verifies:

1. Reset values for the AXI ready/valid signals.
2. A full 32-bit write followed by a read from the same address.
3. A partial byte write using `wstrb`, then a readback check.
4. A write where the `W` channel arrives before the `AW` channel.
5. The write response channel keeps `bvalid` asserted while `bready` is low.
6. The read data channel keeps `rvalid` and `rdata` stable while `rready` is low.
7. A near-collision between a ready write transaction and a read transaction on
   the shared SRAM interface.

The AW/W versus AR collision test verifies that:

1. The SRAM address corresponds to the transaction selected by the adapter.
2. An active write never uses the read address `araddr`.
3. The losing read transaction remains pending while the write is served.
4. The pending read is executed after the write completes.
5. The final SRAM contents at both addresses are correct.

## How To Run With Icarus Verilog

From the project root, create and enter the simulation directory:

```sh
cd /home/arimeg01/Workspace/soc-project
mkdir -p sim
cd sim

iverilog -g2012 -Wall \
  -o aximem_ss_tb.vvp \
  ../tb/aximem_ss_tb.sv \
  ../rtl/mem_interface/aximem_ss.v \
  ../rtl/mem_interface/axi_slave_adapter.v \
  ../rtl/mem_interface/sram.v

vvp aximem_ss_tb.vvp
```

## How To Run With ModelSim / QuestaSim

From the project root, create and enter the simulation directory:

```sh
cd /home/arimeg01/Workspace/soc-project
mkdir -p sim
cd sim

rm -rf work
vlib work

vlog -64 -sv -timescale 1ns/1ps -f ../tb/filelist.f -work work -l vlog.log

vsim -64 -voptargs=+acc work.aximem_ss_tb -l vsim.log -do "run -all; quit"
```

For an interactive GUI run, use:

```sh
vsim -64 -voptargs=+acc work.aximem_ss_tb -l vsim.log
```

Then in the Questa transcript:

```tcl
view wave
add wave -r sim:/aximem_ss_tb/*
run -all
```

## How To Run With Quartus

Quartus is mainly used for synthesis, but the testbench can be simulated with
the ModelSim/Questa simulator installed with Quartus.

From the project root, create and enter the simulation directory:

```sh
cd /home/arimeg01/Workspace/soc-project
mkdir -p sim
cd sim

rm -rf work
vlib work

vlog -64 -sv -timescale 1ns/1ps -f ../tb/filelist.f -work work -l vlog.log

vsim -64 -voptargs=+acc work.aximem_ss_tb -l vsim.log -do "run -all; quit"
```

## How To Run With Vivado

From the project root, create and enter the simulation directory:

```sh
cd /home/arimeg01/Workspace/soc-project
mkdir -p sim
cd sim

xvlog -sv \
  ../tb/aximem_ss_tb.sv \
  ../rtl/mem_interface/aximem_ss.v \
  ../rtl/mem_interface/axi_slave_adapter.v \
  ../rtl/mem_interface/sram.v

xelab aximem_ss_tb -s aximem_ss_tb_sim
xsim aximem_ss_tb_sim -runall
```

## Expected Result

The simulation should print several `[PASS]` lines and finish with:

```text
[PASS] aximem_ss_tb completed successfully
```

The AW/W versus AR collision test also prints:

```text
[INFO] starting AW/W versus AR SRAM arbitration test
```

The testbench also generates this waveform file:

```text
/home/arimeg01/Workspace/soc-project/sim/aximem_ss_tb.vcd
```

The VCD is created in the simulation directory because the commands above run
from `/home/arimeg01/Workspace/soc-project/sim` and the testbench uses:

```systemverilog
$dumpfile("aximem_ss_tb.vcd");
```
