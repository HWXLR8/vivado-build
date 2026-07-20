
module memmap
  (input         clk,
   input [15:0]  cpu_addr,
   output [7:0]  cpu_rd_data,      // memmap -> CPU
   input [7:0]   cpu_wr_data,
   input         cpu_we,

   output [12:0] cpu_vram_addr,
   input [7:0]   cpu_vram_rd_data, // VRAM -> memmap
   output [7:0]  cpu_vram_wr_data,
   output        cpu_vram_we,

   output [12:0] rom_addr,
   input [7:0]   rom_data,

   output [9:0]  ram_addr,
   input [7:0]   ram_rd_data,
   output [7:0]  ram_wr_data,
   output        ram_we);

   // 0x0000 - 0x1FFF : ROM
   // 0x2000 - 0x23FF : RAM
   // 0x2400 - 0x3FFF : VRAM
   // 0x4000 -        : MIRROR


   wire [15:0] mapped_addr = cpu_addr & 16'h3FFF; // discard top 2 bits
   wire in_rom = mapped_addr < 16'h2000;
   wire in_ram = mapped_addr >= 16'h2000 && mapped_addr < 16'h2400;
   wire in_vram = mapped_addr >= 16'h2400 && mapped_addr < 16'h4000;

   // for 1-cycle delay
   reg         in_rom_latch;
   reg         in_ram_latch;
   reg         in_vram_latch;

   always @(posedge clk) begin
      in_rom_latch <= in_rom;
      in_ram_latch <= in_ram;
      in_vram_latch <= in_vram;
   end

   assign ram_addr = mapped_addr - 16'h2000;
   assign ram_we = (in_ram && cpu_we);
   assign ram_wr_data = cpu_wr_data;

   assign cpu_vram_we = (in_vram && cpu_we);
   assign cpu_vram_addr = mapped_addr - 16'h2400;
   assign cpu_vram_wr_data = cpu_wr_data;

   assign rom_addr = mapped_addr[12:0];

   assign cpu_rd_data = in_rom_latch ? rom_data :
                        in_ram_latch ? ram_rd_data :
                        in_vram_latch ? cpu_vram_rd_data :
                        8'h00;
endmodule
