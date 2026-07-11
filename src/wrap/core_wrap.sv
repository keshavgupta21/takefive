`include "common.svh"

module core_wrap (
    input  logic        clk,
    input  logic        rst,
    input  logic        dbg_prog,

    output logic        dbg_pause,
    output logic [31:0] dbg_pc,
    output logic        dbg_commit,
    output logic        dbg_pipe_busy,

    `s_axil_intf        (mmio),
    `m_axis_intf        (axis),
    `s_axis_intf        (axis),
    `m_axi_intf         (imem),
    `m_axi_intf         (dmem)
);

    core u_core(
        .clk            (clk            ),
        .rst            (rst            ),
        .dbg_prog       (dbg_prog       ),
        .dbg_pause      (dbg_pause      ),
        .dbg_pc         (dbg_pc         ),
        .dbg_commit     (dbg_commit     ),
        .dbg_pipe_busy  (dbg_pipe_busy  ),
        `axil_bind      (mmio, mmio     ),
        `m_axis_bind    (axis, axis     ),
        `s_axis_bind    (axis, axis     ),
        `axi_bind       (imem, imem     ),
        `axi_bind       (dmem, dmem     )
    );

endmodule
