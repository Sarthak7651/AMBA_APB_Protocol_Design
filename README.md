# AMBA APB Protocol Design

Verilog implementations of the **AMBA APB (Advanced Peripheral Bus)** protocol, built step by step: a master and slave without wait states (APB2 style), a version with wait states (APB3 style), a slave that reports errors through `PSLVERR`, peripheral cores (register and FIFO) with an APB interface, and a single master connected to multiple slaves.

The protocol reference used for this work is included in the repo: `IHI0024E_amba_apb_architecture_spec.pdf`.

## APB Basics

Every APB transfer takes at least two clock cycles:

| Phase  | PSEL | PENABLE | What happens                                              |
|--------|------|---------|-----------------------------------------------------------|
| Setup  | 1    | 0       | Master drives `PADDR`, `PWRITE` and `PWDATA` (for writes) |
| Access | 1    | 1       | Slave completes the transfer and asserts `PREADY`         |

In the designs here, the master and slaves are small FSMs:

- **Master:** `idle -> setup -> enable`. A new request (`newd`) starts a transfer; in `enable` the master waits for `PREADY` before finishing or starting the next transfer.
- **Slave:** `idle -> write` or `read`, based on `PSEL` and `PWRITE`; the transfer completes in the access phase.

## Repository Structure

```
.
├── IHI0024E_amba_apb_architecture_spec.pdf
├── RTL_Code/
│   ├── apb2_no_wait_state/        # master + slave, no wait states
│   ├── apb3_wait_state/           # master + slave, wait states via s_wait
│   └── slave_with_SLVERR/         # slave with PSLVERR error reporting
├── building_apb_cores/            # APB register and APB FIFO
└── single_master_multi_slave/     # one master, two slaves
```

### 1. `RTL_Code/apb2_no_wait_state`

| File | Description |
|------|-------------|
| `abp2_master.v` | APB master (`apb_m`): takes `addrin[3:0]`, `datain[7:0]`, `wr`, `newd` and drives the APB signals; `dataout` returns read data |
| `apb2_slave.v` | APB slave (`apb_s`): 16 x 8-bit memory, `PREADY` and `PRDATA` outputs |
| `apb2_master_slave.v` | Top module connecting the master and the slave |
| `tb_apb2_master.v`, `tb_apb2_slave.v`, `tb_apb2_master_slave.v` | Testbenches |
| `apb_master_waveform.png`, `apb_slave_waveform.png` | Simulation waveforms |

### 2. `RTL_Code/apb3_wait_state`

Same structure as above, with wait-state support. The slave (`apb3_s`) has an extra `s_wait` input: while it is high in the access phase, the slave does not complete the transfer, so the master stays in `enable` until `PREADY` is asserted.

| File | Description |
|------|-------------|
| `apb3_master.v` | APB master (`apb3_m`) |
| `apb3_slave.v` | APB slave (`apb3_s`) with `s_wait` input |
| `apb3_master_slave.v` | Top module connecting master and slave |
| `tb_apb3_*.v` | Testbenches |

### 3. `RTL_Code/slave_with_SLVERR`

`apb3_slave_pslverr.v` is a slave with a 32-bit `PADDR`, 16 x 8-bit memory and a `PSLVERR` output. An access with an out-of-range address (`PADDR > 15`) is completed with `PSLVERR` asserted during the access phase. The testbench `tb_apb3_slave_pslverr.v` applies valid and invalid writes and reads.

### 4. `building_apb_cores`

APB-attached peripheral cores:

| File | Description |
|------|-------------|
| `apb_register.v` | 32-bit GPIO register at address `0x0000_0000`, read and written over APB with `PREADY` handshaking |
| `apb_fifo.v` | 16-deep, 32-bit FIFO with write and read pointers and an entry counter, accessed over APB |
| `tb_apb_reg.v`, `tb_apb_fifo.v` | Testbenches |

### 5. `single_master_multi_slave`

One APB master driving two slaves. The master selects the slave using `slv_addr_in` (`2'b01` = slave 1, `2'b10` = slave 2) and generates `PSEL1` or `PSEL2`. The top module muxes `PRDATA`, `PREADY` and `PSLVERR` back from the selected slave.

| File | Description |
|------|-------------|
| `apb_master_top.v` | Master with two select lines |
| `apb_slave_top.v` | Slave with 16 x 8-bit memory and `PSLVERR` (instantiated twice) |
| `apb_multi_slave_top_module.v` | Top module: master + two slaves + response mux |
| `tb_multi_slave_top_module.v` | Testbench: writes to both slaves, then reads back from slave 1 |
| `*.pdf` | Block diagrams of the master, slave and multi-slave top |

## How to Run

Any Verilog/SystemVerilog simulator can be used (Icarus Verilog, Vivado XSim, EDA Playground, ...). Some testbenches use SystemVerilog constructs, so enable SystemVerilog mode.

Example with Icarus Verilog (single master + two slaves):

```bash
iverilog -g2012 -o sim \
  single_master_multi_slave/apb_master_top.v \
  single_master_multi_slave/apb_slave_top.v \
  single_master_multi_slave/apb_multi_slave_top_module.v \
  single_master_multi_slave/tb_multi_slave_top_module.v
vvp sim
```

Master + slave without wait states:

```bash
iverilog -g2012 -o sim \
  RTL_Code/apb2_no_wait_state/abp2_master.v \
  RTL_Code/apb2_no_wait_state/apb2_slave.v \
  RTL_Code/apb2_no_wait_state/apb2_master_slave.v \
  RTL_Code/apb2_no_wait_state/tb_apb2_master_slave.v
vvp sim
```

Testbenches dump waveforms or end with `$stop`; open the waveform in GTKWave or your simulator's viewer.

## Concepts Covered

- APB setup and access phases, `PSEL` / `PENABLE` / `PREADY` handshake
- FSM-based master and slave design
- Wait states (APB3) and slave error reporting (`PSLVERR`)
- Memory-mapped peripherals: register and FIFO behind an APB interface
- Address decoding with multiple slaves and response muxing

## Author

Sarthak
