`include "common.svh"

module core #(
    parameter DEBUG_EN = 0
)(
    input  logic                   clk,
    input  logic                   rst,

    output takefive_pkg::mem_req_t imem_req,
    input  takefive_pkg::mem_rsp_t imem_rsp,
    input  logic                   imem_rdy,

    output takefive_pkg::mem_req_t dmem_req,
    input  takefive_pkg::mem_rsp_t dmem_rsp,
    input  logic                   dmem_rdy,

    input  logic                   dbg_pause,
    input  logic [4:0]             dbg_rs,
    output logic [31:0]            dbg_pc,
    output logic [31:0]            dbg_rval,
    output logic                   dbg_commit,
    input  logic                   dbg_rf_wr,
    input  logic [4:0]             dbg_rf_rd,
    input  logic [31:0]            dbg_rf_data
);

    //         --- PIPELINE STAGE 1 ---
    // ---------------- Fetch ----------------
    // (fetch output is flopped)
    takefive_pkg::f2d_t    f2d;
    takefive_pkg::annul_t annul;

    logic dec_stall, rf_stall, dmem_stall, wb_stall, stall;
    assign stall = dec_stall || rf_stall || dmem_stall || wb_stall;

    fetch #(.DEBUG_EN(DEBUG_EN)) u_fetch(
        .clk       (clk      ),
        .rst       (rst      ),
        .mem_req   (imem_req ),
        .mem_rsp   (imem_rsp ),
        .mem_rdy   (imem_rdy ),
        .f2d       (f2d      ),
        .annul     (annul    ),
        .stall     (stall    ),
        .dbg_pause (dbg_pause)
    );

    //         --- PIPELINE STAGE 2 ---
    // ---------------- Decode ----------------
    takefive_pkg::d2r_t d2r;

    dec u_dec(
        .f2d (f2d),
        .d2r (d2r)
    );

    assign dec_stall = !f2d.vld;

    // ---------------- RegFile ----------------
    takefive_pkg::rvals_t rvals;
    takefive_pkg::rfwb_t  rfwb;

    rf #(.DEBUG_EN(DEBUG_EN)) u_rf(
        .clk         (clk         ),
        .rs1         (d2r.inst.rs1),
        .rs2         (d2r.inst.rs2),
        .rvals       (rvals       ),
        .rfwb        (rfwb        ),
        .dbg_pause   (dbg_pause   ),
        .dbg_rs      (dbg_rs      ),
        .dbg_rval    (dbg_rval    ),
        .dbg_rf_wr   (dbg_rf_wr   ),
        .dbg_rf_rd   (dbg_rf_rd   ),
        .dbg_rf_data (dbg_rf_data )
    );

    takefive_pkg::rvals_t byp_rvals;

    bypass u_bypass(
        .inst      (d2r.inst ),
        .rd_rvals  (rvals    ),
        .r2e       (r2e      ),
        .rfwb      (rfwb     ),
        .byp_rvals (byp_rvals),
        .stall     (rf_stall )
    );

    takefive_pkg::r2e_t r2e;
    always_ff @(posedge clk) begin
        if (rst) begin
            r2e.vld   <= 0;
            r2e.pc    <= '0;
            r2e.inst  <= '0;
            r2e.rvals <= '0;
        end else if (!dmem_stall && !wb_stall) begin
            if (annul.annul || dec_stall || rf_stall) begin
                r2e.vld   <= 0;
                r2e.pc    <= '0;
                r2e.inst  <= '0;
                r2e.rvals <= '0;
            end else begin
                r2e.vld   <= d2r.vld;
                r2e.pc    <= d2r.pc;
                r2e.inst  <= d2r.inst;
                r2e.rvals <= byp_rvals;
            end
        end
    end

    //         --- PIPELINE STAGE 3 ---
    // ---------------- Execute / Mem ----------------
    branch u_branch(
        .r2e   (r2e  ),
        .annul (annul)
    );
    
    logic [31:0] alu_out;

    alu u_alu(
        .r2e     (r2e    ),
        .alu_out (alu_out)
    );

    mem u_mem(
        .r2e      (r2e       ),
        .dmem_rdy (dmem_rdy  ),
        .mem_req  (dmem_req  ),
        .stall    (dmem_stall)
    );

    takefive_pkg::e2w_t e2w;
    always_ff @(posedge clk) begin
        if (rst) begin
            e2w.vld     <= 0;
            e2w.pc      <= '0;
            e2w.inst    <= '0;
            e2w.rvals   <= '0;
            e2w.alu_out <= '0;
        end else if (!wb_stall) begin
            if (dmem_stall) begin
                e2w.vld     <= 0;
                e2w.pc      <= '0;
                e2w.inst    <= '0;
                e2w.rvals   <= '0;
                e2w.alu_out <= '0;
            end else begin
                e2w.vld     <= r2e.vld;
                e2w.pc      <= r2e.pc;
                e2w.inst    <= r2e.inst;
                e2w.rvals   <= r2e.rvals;
                e2w.alu_out <= alu_out;
            end
        end
    end

    //         --- PIPELINE STAGE 4 ---
    // ---------------- Writeback ----------------
    wb u_wb(
        .e2w      (e2w      ),
        .dmem_rsp (dmem_rsp ),
        .rfwb     (rfwb     ),
        .stall    (wb_stall )
    );

    always_ff @(posedge clk) begin
        if (rst || wb_stall) begin
            dbg_pc     <= '0;
            dbg_commit <= 0;
        end else begin
            dbg_pc     <= e2w.pc;
            dbg_commit <= e2w.vld;
        end
    end

endmodule
