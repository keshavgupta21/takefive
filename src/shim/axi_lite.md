# AXI4-Lite Slave Interface Notes

## 1. Write State Machine

**File:** `src/shim/takfive_shim_slave_lite_v1_0_S00_AXI.v`

Three states: `Idle → Waddr ↔ Wdata`.

**Idle** (2'b00): asserts both `awready = 1` and `wready = 1`, then unconditionally moves to `Waddr` on the next cycle.

**Waddr** (2'b10): the common steady state. On an AW-channel handshake (`AWVALID && AWREADY`), it latches `axi_awaddr`. Then:
- If `WVALID` is already asserted (address + data arrive together — the normal AXI-Lite case): sets `bvalid = 1`, keeps `awready = 1`, and **stays in `Waddr`** to accept the next transaction back-to-back.
- If `WVALID` is not yet asserted: drops `awready = 0`, moves to **Wdata** to wait for data.

**Wdata** (2'b11): when `WVALID` arrives, sets `bvalid = 1`, re-asserts `awready = 1`, and returns to `Waddr`.

`bvalid` is cleared whenever `BREADY && bvalid` is seen while idling in `Waddr` or `Wdata`.

The actual register write is a **separate** always block triggered on `S_AXI_WVALID`. The address is `S_AXI_AWADDR` if `AWVALID` is asserted in the same cycle (same-cycle address+data path), otherwise `axi_awaddr` (latched). Write data is byte-steered via `WSTRB`.

---

## 2. Read State Machine Differences

**Files:** `src/shim/takfive_shim_slave_lite_v1_0_S00_AXI.v` (reference) vs `src/rtl/shim.sv` (ours)

Both share the same three-state skeleton (`Idle → Raddr → Rdata → Raddr`), but differ in several important ways:

| Aspect | `takfive_shim_slave_lite_v1_0_S00_AXI.v` | `shim.sv` |
|---|---|---|
| **Reset polarity** | Active-low `ARESETN == 0` | Active-high `rst` |
| **Data source** | Combinational 64-way ternary chain from registered `axi_araddr` — zero latency after `rvalid` rises | Synchronous BRAM read: `rdata_reg` is latched on the `ar_handshake` cycle, one cycle before `rvalid` rises |
| **Read address for data** | Always uses registered `axi_araddr` | Muxes `ar_handshake ? live_araddr : latched_araddr` to feed the BRAM read port early, so data is ready by the time `rvalid` is set |
| **Out-of-range read** | Falls through the ternary; returns 0 implicitly | Explicit `if (addr < DATA_WORDS) rdata_reg <= mmio_rdata; else rdata_reg <= 0` |
| **Self-loops** | Explicit `state_read <= state_read` in every idle branch | Omitted (synthesizes identically) |
| **Idle redundancy** | Checks `ARESETN == 1` again inside the non-reset branch | No such redundancy |
| **`rresp` reset** | Reset to `1'b0` (1-bit literal assigned to a 2-bit reg — works but imprecise) | Driven combinationally as `2'b00` outside the FSM |

The most consequential difference is data timing: the reference drives `S_AXI_RDATA` purely combinationally, so data is valid the same cycle `RVALID` rises. Our shim uses a synchronous BRAM, so it pre-reads on the handshake cycle and registers the result into `rdata_reg` — the data is ready by the time `RVALID` rises, but the BRAM read must have been set up a cycle earlier via `dpra_sel`.
