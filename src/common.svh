`default_nettype none

// ---------------------------------------------------------------------------
// AXI-Lite port declarations
// ---------------------------------------------------------------------------

// Slave: module receives commands from master; addr_w=8, data_w=32
`define s_axil_intf(name) \
    input  logic [7:0]  s_``name``_araddr, \
    input  logic [2:0]  s_``name``_arprot, \
    input  logic        s_``name``_arvalid, \
    output logic        s_``name``_arready, \
    output logic [31:0] s_``name``_rdata, \
    output logic [1:0]  s_``name``_rresp, \
    output logic        s_``name``_rvalid, \
    input  logic        s_``name``_rready, \
    input  logic [7:0]  s_``name``_awaddr, \
    input  logic [2:0]  s_``name``_awprot, \
    input  logic        s_``name``_awvalid, \
    output logic        s_``name``_awready, \
    input  logic [31:0] s_``name``_wdata, \
    input  logic [3:0]  s_``name``_wstrb, \
    input  logic        s_``name``_wvalid, \
    output logic        s_``name``_wready, \
    output logic [1:0]  s_``name``_bresp, \
    output logic        s_``name``_bvalid, \
    input  logic        s_``name``_bready

// Master (32-bit addr + data): drives commands over a full AXI bus
`define m_axi_intf(name) \
    output logic [31:0] m_``name``_araddr, \
    output logic [2:0]  m_``name``_arprot, \
    output logic        m_``name``_arvalid, \
    input  logic        m_``name``_arready, \
    input  logic [31:0] m_``name``_rdata, \
    input  logic [1:0]  m_``name``_rresp, \
    input  logic        m_``name``_rvalid, \
    output logic        m_``name``_rready, \
    output logic [31:0] m_``name``_awaddr, \
    output logic [2:0]  m_``name``_awprot, \
    output logic        m_``name``_awvalid, \
    input  logic        m_``name``_awready, \
    output logic [31:0] m_``name``_wdata, \
    output logic [3:0]  m_``name``_wstrb, \
    output logic        m_``name``_wvalid, \
    input  logic        m_``name``_wready, \
    input  logic [1:0]  m_``name``_bresp, \
    input  logic        m_``name``_bvalid, \
    output logic        m_``name``_bready

// m_axi_tie(name): passthrough connection for m_axi_intf ports
`define m_axi_tie(name) \
    .m_``name``_araddr  (m_``name``_araddr ), \
    .m_``name``_arprot  (m_``name``_arprot ), \
    .m_``name``_arvalid (m_``name``_arvalid), \
    .m_``name``_arready (m_``name``_arready), \
    .m_``name``_rdata   (m_``name``_rdata  ), \
    .m_``name``_rresp   (m_``name``_rresp  ), \
    .m_``name``_rvalid  (m_``name``_rvalid ), \
    .m_``name``_rready  (m_``name``_rready ), \
    .m_``name``_awaddr  (m_``name``_awaddr ), \
    .m_``name``_awprot  (m_``name``_awprot ), \
    .m_``name``_awvalid (m_``name``_awvalid), \
    .m_``name``_awready (m_``name``_awready), \
    .m_``name``_wdata   (m_``name``_wdata  ), \
    .m_``name``_wstrb   (m_``name``_wstrb  ), \
    .m_``name``_wvalid  (m_``name``_wvalid ), \
    .m_``name``_wready  (m_``name``_wready ), \
    .m_``name``_bresp   (m_``name``_bresp  ), \
    .m_``name``_bvalid  (m_``name``_bvalid ), \
    .m_``name``_bready  (m_``name``_bready )

// Master (8-bit addr, 32-bit data): drives commands to slave
`define m_axil_intf(name) \
    output logic [7:0]  m_``name``_araddr, \
    output logic [2:0]  m_``name``_arprot, \
    output logic        m_``name``_arvalid, \
    input  logic        m_``name``_arready, \
    input  logic [31:0] m_``name``_rdata, \
    input  logic [1:0]  m_``name``_rresp, \
    input  logic        m_``name``_rvalid, \
    output logic        m_``name``_rready, \
    output logic [7:0]  m_``name``_awaddr, \
    output logic [2:0]  m_``name``_awprot, \
    output logic        m_``name``_awvalid, \
    input  logic        m_``name``_awready, \
    output logic [31:0] m_``name``_wdata, \
    output logic [3:0]  m_``name``_wstrb, \
    output logic        m_``name``_wvalid, \
    input  logic        m_``name``_wready, \
    input  logic [1:0]  m_``name``_bresp, \
    input  logic        m_``name``_bvalid, \
    output logic        m_``name``_bready

// ---------------------------------------------------------------------------
// AXI Stream port declarations (data_w=32)
// ---------------------------------------------------------------------------

// Master: module drives tvalid/tdata
`define m_axis_intf(name) \
    output logic        m_``name``_tvalid, \
    input  logic        m_``name``_tready, \
    output logic [31:0] m_``name``_tdata

// Slave: module receives tvalid/tdata plus a level sideband
`define s_axis_intf(name) \
    input  logic        s_``name``_tvalid, \
    output logic        s_``name``_tready, \
    input  logic [31:0] s_``name``_tdata, \
    input  logic [31:0] s_``name``_level

// ---------------------------------------------------------------------------
// AXI-Lite instantiation connections
// ---------------------------------------------------------------------------

// s_axil_passtie(name): passthrough — sub-module ports are s_<name>_araddr etc.
`define s_axil_passtie(name) \
    .s_``name``_araddr  (s_``name``_araddr), \
    .s_``name``_arprot  (s_``name``_arprot), \
    .s_``name``_arvalid (s_``name``_arvalid), \
    .s_``name``_arready (s_``name``_arready), \
    .s_``name``_rdata   (s_``name``_rdata), \
    .s_``name``_rresp   (s_``name``_rresp), \
    .s_``name``_rvalid  (s_``name``_rvalid), \
    .s_``name``_rready  (s_``name``_rready), \
    .s_``name``_awaddr  (s_``name``_awaddr), \
    .s_``name``_awprot  (s_``name``_awprot), \
    .s_``name``_awvalid (s_``name``_awvalid), \
    .s_``name``_awready (s_``name``_awready), \
    .s_``name``_wdata   (s_``name``_wdata), \
    .s_``name``_wstrb   (s_``name``_wstrb), \
    .s_``name``_wvalid  (s_``name``_wvalid), \
    .s_``name``_wready  (s_``name``_wready), \
    .s_``name``_bresp   (s_``name``_bresp), \
    .s_``name``_bvalid  (s_``name``_bvalid), \
    .s_``name``_bready  (s_``name``_bready)

// ---------------------------------------------------------------------------
// AXI Stream instantiation connections
// ---------------------------------------------------------------------------

// m_axis_tie(name): connect .m_<name>_t* ports to m_<name>_t* signals
`define m_axis_tie(name) \
    .m_``name``_tvalid (m_``name``_tvalid), \
    .m_``name``_tready (m_``name``_tready), \
    .m_``name``_tdata  (m_``name``_tdata)

// s_axis_tie(name): connect .s_<name>_t*/level ports to s_<name>_t*/level signals
`define s_axis_tie(name) \
    .s_``name``_tvalid (s_``name``_tvalid), \
    .s_``name``_tready (s_``name``_tready), \
    .s_``name``_tdata  (s_``name``_tdata), \
    .s_``name``_level  (s_``name``_level)
