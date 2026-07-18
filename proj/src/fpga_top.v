module fpga_top(
  input         btn,
  output        led,
  output [3:0]  vga_r,
  output [3:0]  vga_g,
  output [3:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,

  inout [14:0]  DDR_addr,
  inout [2:0]   DDR_ba,
  inout         DDR_cas_n,
  inout         DDR_ck_n,
  inout         DDR_ck_p,
  inout         DDR_cke,
  inout         DDR_cs_n,
  inout [3:0]   DDR_dm,
  inout [31:0]  DDR_dq,
  inout [3:0]   DDR_dqs_n,
  inout [3:0]   DDR_dqs_p,
  inout         DDR_odt,
  inout         DDR_ras_n,
  inout         DDR_reset_n,
  inout         DDR_we_n,

  inout         FIXED_IO_ddr_vrn,
  inout         FIXED_IO_ddr_vrp,
  inout [53:0]  FIXED_IO_mio,
  inout         FIXED_IO_ps_clk,
  inout         FIXED_IO_ps_porb,
  inout         FIXED_IO_ps_srstb
);

   // -------------------------------------------------------------------------
   // Clock
   // -------------------------------------------------------------------------
   wire clk;

   // -------------------------------------------------------------------------
   // VGA <-> VRAM video read port
   // -------------------------------------------------------------------------
   wire [12:0] vga_vram_rd_addr;
   wire [7:0]  vga_vram_rd_data;

   // -------------------------------------------------------------------------
   // Memory map <-> VRAM CPU port
   // -------------------------------------------------------------------------
   wire [12:0] cpu_vram_addr;
   wire [7:0]  cpu_vram_rd_data;
   wire [7:0]  cpu_vram_wr_data;
   wire        cpu_vram_we;

   // -------------------------------------------------------------------------
   // Memory map <-> ROM
   // -------------------------------------------------------------------------
   wire [12:0] rom_addr;
   wire [7:0]  rom_data;

   // -------------------------------------------------------------------------
   // Memory map <-> RAM
   // -------------------------------------------------------------------------
   wire [9:0]  ram_addr;
   wire [7:0]  ram_rd_data;
   wire [7:0]  ram_wr_data;
   wire        ram_we;

   // -------------------------------------------------------------------------
   // CPU core <-> light8080 adapter
   // -------------------------------------------------------------------------
   wire        l80_vma;
   wire        l80_io;
   wire        l80_rd;
   wire        l80_wr;
   wire [7:0]  l80_data_out;
   wire [7:0]  l80_data_in;
   wire [15:0] l80_addr_out;

   // -------------------------------------------------------------------------
   // light8080 adapter <-> memory map
   // -------------------------------------------------------------------------
   wire [15:0] cpu_addr;
   wire [7:0]  cpu_rd_data;
   wire [7:0]  cpu_wr_data;
   wire        cpu_we;

   // debug LED, prove that CPU is fetching opcodes
   wire        l80_fetch;
   reg [23:0]  fetch_count;
   always @(posedge clk) begin
      if (btn)
        fetch_count <= 24'd0;
      else if (l80_fetch)
        fetch_count <= fetch_count + 1'b1;
   end
   assign led = fetch_count[23];

  system_wrapper ps_system (
    .FCLK_CLK0_0(clk),

    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),

    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb)
  );

   vga vga_inst (.clk(clk),
                 .vga_r(vga_r),
                 .vga_g(vga_g),
                 .vga_b(vga_b),
                 .vga_hsync(vga_hsync),
                 .vga_vsync(vga_vsync),
                 .vram_rd_addr(vga_vram_rd_addr),
                 .vram_rd_data(vga_vram_rd_data));

   memmap memmap_inst (.cpu_addr(cpu_addr),
                       .cpu_rd_data(cpu_rd_data),
                       .cpu_wr_data(cpu_wr_data),
                       .cpu_we(cpu_we),

                       .cpu_vram_addr(cpu_vram_addr),
                       .cpu_vram_rd_data(cpu_vram_rd_data),
                       .cpu_vram_wr_data(cpu_vram_wr_data),
                       .cpu_vram_we(cpu_vram_we),

                       .rom_addr(rom_addr),
                       .rom_data(rom_data),

                       .ram_addr(ram_addr),
                       .ram_rd_data(ram_rd_data),
                       .ram_wr_data(ram_wr_data),
                       .ram_we(ram_we));

   rom rom_inst (.clk(clk),
                 .addr(rom_addr),
                 .data(rom_data));

   ram ram_inst (.clk(clk),
                 .addr(ram_addr),
                 .rd_data(ram_rd_data),
                 .wr_data(ram_wr_data),
                 .we(ram_we));

   vram vram_inst (.clk(clk),
                   // vga port
                   .vram_rd_addr(vga_vram_rd_addr),
                   .vram_rd_data(vga_vram_rd_data),
                   // cpu port
                   .cpu_addr(cpu_vram_addr),
                   .cpu_rd_data(cpu_vram_rd_data),
                   .cpu_wr_data(cpu_vram_wr_data),
                   .cpu_we(cpu_vram_we));

   light8080 l8080 (.clk(clk),
                    .reset(btn),
                    .addr_out(l80_addr_out),
                    .vma(l80_vma),
                    .io(l80_io),
                    .rd(l80_rd),
                    .wr(l80_wr),
                    .data_in(l80_data_in),
                    .data_out(l80_data_out),
                    .fetch(l80_fetch),
                    .inta(),
                    .inte(),
                    .halt(),
                    .intr(1'b0));

  light8080_adapter l8080_adapter (.vma(l80_vma),
                                   .io(l80_io),
                                   .rd(l80_rd),
                                   .wr(l80_wr),
                                   .data_out(l80_data_out),
                                   .addr_out(l80_addr_out),
                                   .data_in(l80_data_in),
                                   .memmap_cpu_addr(cpu_addr),
                                   .memmap_cpu_wr_data(cpu_wr_data),
                                   .memmap_cpu_we(cpu_we),
                                   .memmap_cpu_rd_data(cpu_rd_data));




endmodule
