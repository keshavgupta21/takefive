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
    `m_axi_intf         (imem_axi),
    `m_axi_intf         (dmem_axi)
);

    core u_core(
        .clk            (clk            ),
        .rst            (rst            ),
        .dbg_prog       (dbg_prog       ),
        .dbg_pause      (dbg_pause      ),
        .dbg_pc         (dbg_pc         ),
        .dbg_commit     (dbg_commit     ),
        .dbg_pipe_busy  (dbg_pipe_busy  ),
        `s_axil_passtie (mmio           ),
        `m_axis_tie     (axis           ),
        `s_axis_tie     (axis           ),
        `m_axi_tie      (imem_axi       ),
        `m_axi_tie      (dmem_axi       )
    );

endmodule
