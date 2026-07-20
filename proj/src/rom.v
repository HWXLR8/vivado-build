module rom (input            clk,
            input [12:0]     addr,
            output reg [7:0] data);

   reg [7:0] mem [0:8191];

   initial begin
      $readmemh("space_invaders.hex", mem);
   end

   always @(posedge clk) begin
      data <= mem[addr];
   end

endmodule
