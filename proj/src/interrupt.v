module interrupt (input            clk,
                  input            rst,
                  // VGA
                  input            int1,
                  input            int2,
                  // CPU
                  input            inta,
                  output reg       intr,
                  output reg [7:0] irq_opcode);

   always @(posedge clk) begin
      if (rst) begin
         intr <= 1'b0;
         irq_opcode <= 8'h00;
      end else begin
         if (int1) begin
            irq_opcode <= 8'hCF;
            intr <= 1'b1;
         end else if (int2) begin
            irq_opcode <= 8'hD7;
            intr <= 1'b1;
         end

         if (inta) begin
            intr <= 1'b0;
         end
      end
   end

endmodule
