module shifter
  (input clk,
   input rst,
   input [7:0] data_in,
   input [2:0] shift, // 0-7
   input data_we,
   input shift_we,
   output [7:0] data_out
);
   reg [2:0] stored_shift;
   reg [15:0] stored_data;

   assign data_out = (stored_data << stored_shift) >> 8;

   always @(posedge clk) begin
      if (rst) begin
         stored_shift <= 3'b000;
         stored_data <= 16'h0000;
      end else begin

         // update shift
         if (shift_we) begin
            stored_shift <= shift;
         end

         // update data
         if (data_we) begin
            stored_data <= {data_in, stored_data[15:8]};
         end
      end

   end
endmodule
