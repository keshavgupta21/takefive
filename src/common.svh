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
// Wire port declarations (plain Verilog, e.g. for Vivado wrappers)
// ---------------------------------------------------------------------------

// Slave: module receives commands from master; addr_w=8, data_w=32
`define s_axil_intf_wire(name) \
    input  wire [7:0]  s_``name``_araddr, \
    input  wire [2:0]  s_``name``_arprot, \
    input  wire        s_``name``_arvalid, \
    output wire        s_``name``_arready, \
    output wire [31:0] s_``name``_rdata, \
    output wire [1:0]  s_``name``_rresp, \
    output wire        s_``name``_rvalid, \
    input  wire        s_``name``_rready, \
    input  wire [7:0]  s_``name``_awaddr, \
    input  wire [2:0]  s_``name``_awprot, \
    input  wire        s_``name``_awvalid, \
    output wire        s_``name``_awready, \
    input  wire [31:0] s_``name``_wdata, \
    input  wire [3:0]  s_``name``_wstrb, \
    input  wire        s_``name``_wvalid, \
    output wire        s_``name``_wready, \
    output wire [1:0]  s_``name``_bresp, \
    output wire        s_``name``_bvalid, \
    input  wire        s_``name``_bready

// Master (32-bit addr + data): drives commands over a full AXI bus
`define m_axi_intf_wire(name) \
    output wire [31:0] m_``name``_araddr, \
    output wire [2:0]  m_``name``_arprot, \
    output wire        m_``name``_arvalid, \
    input  wire        m_``name``_arready, \
    input  wire [31:0] m_``name``_rdata, \
    input  wire [1:0]  m_``name``_rresp, \
    input  wire        m_``name``_rvalid, \
    output wire        m_``name``_rready, \
    output wire [31:0] m_``name``_awaddr, \
    output wire [2:0]  m_``name``_awprot, \
    output wire        m_``name``_awvalid, \
    input  wire        m_``name``_awready, \
    output wire [31:0] m_``name``_wdata, \
    output wire [3:0]  m_``name``_wstrb, \
    output wire        m_``name``_wvalid, \
    input  wire        m_``name``_wready, \
    input  wire [1:0]  m_``name``_bresp, \
    input  wire        m_``name``_bvalid, \
    output wire        m_``name``_bready

// Master (8-bit addr, 32-bit data): drives commands to slave
`define m_axil_intf_wire(name) \
    output wire [7:0]  m_``name``_araddr, \
    output wire [2:0]  m_``name``_arprot, \
    output wire        m_``name``_arvalid, \
    input  wire        m_``name``_arready, \
    input  wire [31:0] m_``name``_rdata, \
    input  wire [1:0]  m_``name``_rresp, \
    input  wire        m_``name``_rvalid, \
    output wire        m_``name``_rready, \
    output wire [7:0]  m_``name``_awaddr, \
    output wire [2:0]  m_``name``_awprot, \
    output wire        m_``name``_awvalid, \
    input  wire        m_``name``_awready, \
    output wire [31:0] m_``name``_wdata, \
    output wire [3:0]  m_``name``_wstrb, \
    output wire        m_``name``_wvalid, \
    input  wire        m_``name``_wready, \
    input  wire [1:0]  m_``name``_bresp, \
    input  wire        m_``name``_bvalid, \
    output wire        m_``name``_bready

// Master: module drives tvalid/tdata
`define m_axis_intf_wire(name) \
    output wire        m_``name``_tvalid, \
    input  wire        m_``name``_tready, \
    output wire [31:0] m_``name``_tdata

// Slave: module receives tvalid/tdata plus a level sideband
`define s_axis_intf_wire(name) \
    input  wire        s_``name``_tvalid, \
    output wire        s_``name``_tready, \
    input  wire [31:0] s_``name``_tdata, \
    input  wire [31:0] s_``name``_level

// ---------------------------------------------------------------------------
// Instantiation connection macros
// ---------------------------------------------------------------------------

// axi_bind(m, s): connect sub-module's m_<m>_* AXI ports to parent's m_<s>_* signals
`define axi_bind(m, s) \
    .m_``m``_araddr  (m_``s``_araddr ), \
    .m_``m``_arprot  (m_``s``_arprot ), \
    .m_``m``_arvalid (m_``s``_arvalid), \
    .m_``m``_arready (m_``s``_arready), \
    .m_``m``_rdata   (m_``s``_rdata  ), \
    .m_``m``_rresp   (m_``s``_rresp  ), \
    .m_``m``_rvalid  (m_``s``_rvalid ), \
    .m_``m``_rready  (m_``s``_rready ), \
    .m_``m``_awaddr  (m_``s``_awaddr ), \
    .m_``m``_awprot  (m_``s``_awprot ), \
    .m_``m``_awvalid (m_``s``_awvalid), \
    .m_``m``_awready (m_``s``_awready), \
    .m_``m``_wdata   (m_``s``_wdata  ), \
    .m_``m``_wstrb   (m_``s``_wstrb  ), \
    .m_``m``_wvalid  (m_``s``_wvalid ), \
    .m_``m``_wready  (m_``s``_wready ), \
    .m_``m``_bresp   (m_``s``_bresp  ), \
    .m_``m``_bvalid  (m_``s``_bvalid ), \
    .m_``m``_bready  (m_``s``_bready )

// axil_bind(m, s): connect sub-module's s_<m>_* AXI-Lite ports to parent's s_<s>_* signals
`define axil_bind(m, s) \
    .s_``m``_araddr  (s_``s``_araddr ), \
    .s_``m``_arprot  (s_``s``_arprot ), \
    .s_``m``_arvalid (s_``s``_arvalid), \
    .s_``m``_arready (s_``s``_arready), \
    .s_``m``_rdata   (s_``s``_rdata  ), \
    .s_``m``_rresp   (s_``s``_rresp  ), \
    .s_``m``_rvalid  (s_``s``_rvalid ), \
    .s_``m``_rready  (s_``s``_rready ), \
    .s_``m``_awaddr  (s_``s``_awaddr ), \
    .s_``m``_awprot  (s_``s``_awprot ), \
    .s_``m``_awvalid (s_``s``_awvalid), \
    .s_``m``_awready (s_``s``_awready), \
    .s_``m``_wdata   (s_``s``_wdata  ), \
    .s_``m``_wstrb   (s_``s``_wstrb  ), \
    .s_``m``_wvalid  (s_``s``_wvalid ), \
    .s_``m``_wready  (s_``s``_wready ), \
    .s_``m``_bresp   (s_``s``_bresp  ), \
    .s_``m``_bvalid  (s_``s``_bvalid ), \
    .s_``m``_bready  (s_``s``_bready )

// m_axis_bind(m, s): connect sub-module's m_<m>_t* AXI-Stream ports to parent's m_<s>_t* signals
`define m_axis_bind(m, s) \
    .m_``m``_tvalid (m_``s``_tvalid), \
    .m_``m``_tready (m_``s``_tready), \
    .m_``m``_tdata  (m_``s``_tdata )

// s_axis_bind(m, s): connect sub-module's s_<m>_t*/level ports to parent's s_<s>_t*/level signals
`define s_axis_bind(m, s) \
    .s_``m``_tvalid (s_``s``_tvalid), \
    .s_``m``_tready (s_``s``_tready), \
    .s_``m``_tdata  (s_``s``_tdata ), \
    .s_``m``_level  (s_``s``_level )
