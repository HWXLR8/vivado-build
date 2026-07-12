module vram (input            clk,

             // video read port
             input [12:0]     vid_rd_addr, // 13 bits = 8192 > 7168
             output reg [7:0] vid_rd_data,

             // cpu r/w port
             input [12:0]     cpu_addr,
             output reg [7:0] cpu_rd_data,
             input [7:0]      cpu_wr_data,
             input            cpu_we);

   // byte-indexed fb
   reg [7:0] fb [0:7167];

   initial begin : init_fb
      integer i;
      reg [7:0] pattern;

      for (i = 0; i < 7168; i = i+1) begin
         if (i[2])
           fb[i] = 8'h00;
         else
           fb[i] = 8'hFF;
      end
   end // block: init_fb

   always @(posedge clk) begin
      vid_rd_data <= fb[vid_rd_addr];
   end

   always @(posedge clk) begin
      cpu_rd_data <= fb[cpu_addr];

      if (cpu_we) begin
         fb[cpu_addr] <= cpu_wr_data;
      end
   end

endmodule
