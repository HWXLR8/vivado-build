module ram(input clk,
           input [9:0] addr,
           output reg [7:0] rd_data,
           input [7:0] wr_data,
           input we);

   reg [7:0] mem [0:1023];

   initial begin : init_ram
      integer i;
      for (i = 0; i < 1024; i = i+1)
        mem[i] = 8'h00;
   end

   always @(posedge clk) begin
      rd_data <= mem[addr];

      if (we) begin
         mem[addr] <= wr_data;
      end
   end

endmodule
