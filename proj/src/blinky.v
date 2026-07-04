module blinky(input      clk,
              input      btn,
              output reg led);

   always @(posedge clk)
     led <= ~btn;

endmodule
