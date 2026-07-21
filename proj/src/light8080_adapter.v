// vma :      enable a memory or io r/w access.
// io :       access in progress is io (and not memory)
// rd :       read memory or io
// wr :       write memory or io
// data_out : data output
// addr_out : memory and io address
// data_in :  data input
// halt :     halt status (1 when in halt state)
// inte :     interrupt status (1 when enabled)
// intr :     interrupt request
// inta :     interrupt acknowledge
// reset :    synchronous reset
// clk :      clock

module light8080_adapter
  (input         vma,
   input         io,
   input         rd,
   input         wr,
   input [7:0]   data_out,
   input [15:0]  addr_out,
   output [7:0]  data_in,
   input         inta,
   // fetch,
   // halt,
   // inte,
   // inta,
   // reset,
   // clk

   // memmap
   output [15:0] memmap_cpu_addr,
   input [7:0]   memmap_cpu_rd_data,
   output [7:0]  memmap_cpu_wr_data,
   output        memmap_cpu_we,

   // interrupt
   input [7:0]   irq_opcode,

   // shifter
   input [7:0]   shifter_data_out,
   output [7:0]  shifter_data_in,
   output [2:0]  shifter_shift,
   output        shifter_shift_we,
   output        shifter_data_we
   );

   // io
   wire [7:0] io_port = addr_out[7:0];
   wire       io_wr = io && wr && vma;
   wire       io_rd = io && rd && vma;
   assign shifter_shift_we = (io_wr && io_port == 8'h02);
   assign shifter_data_we = (io_wr && io_port == 8'h04);
   assign shifter_data_in = data_out;
   assign shifter_shift = data_out[2:0];

   // memory
   wire mem_access = vma && !io;
   wire mem_read = mem_access && rd;
   wire mem_write = mem_access && wr;

   assign memmap_cpu_addr = addr_out;
   assign memmap_cpu_wr_data = data_out;
   assign data_in = inta ? irq_opcode :
                    (io_rd && io_port == 8'h03) ? shifter_data_out :
                    memmap_cpu_rd_data;
   assign memmap_cpu_we = mem_write;



endmodule
