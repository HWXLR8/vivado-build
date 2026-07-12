module vga_test(input            clk,
                output reg [3:0] vga_r,
                output reg [3:0] vga_g,
                output reg [3:0] vga_b,
                output reg       vga_hsync,
                output reg       vga_vsync);

   reg [2:0] clk_div = 0;
   wire      pixel_tick = (clk_div == 3'd4);

   localparam H_VISIBLE = 640;
   localparam H_FRONT   = 16;
   localparam H_SYNC    = 96;
   localparam H_BACK    = 48;
   localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

   localparam V_VISIBLE = 480;
   localparam V_FRONT   = 10;
   localparam V_SYNC    = 2;
   localparam V_BACK    = 33;
   localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

   // play area resolution
   localparam H_CANVAS = 256;
   localparam V_CANVAS = 224;
   localparam CANVAS_PX_TOTAL = H_CANVAS * V_CANVAS;

   // centered canvas coords
   localparam H_CANVAS_START = (H_VISIBLE/2) - (H_CANVAS/2);
   localparam H_CANVAS_END = H_CANVAS_START + H_CANVAS;
   localparam V_CANVAS_START = (V_VISIBLE/2) - (V_CANVAS/2);
   localparam V_CANVAS_END = V_CANVAS_START + V_CANVAS;

   reg [9:0]  h_count = 0;
   reg [9:0]  v_count = 0;
   wire [7:0]  canvas_x;
   wire [7:0]  canvas_y;
   wire [16:0] pixel_idx;

   assign canvas_x = h_count - H_CANVAS_START;
   assign canvas_y = v_count - V_CANVAS_START;
   assign pixel_idx = (canvas_y * H_CANVAS) + canvas_x;

   // VRAM
   wire [12:0] vram_rd_addr;
   wire [7:0]  vram_rd_data;
   assign vram_rd_addr = pixel_idx >> 3; // pixel index / 8 to get byte
   vram vram_inst (.clk(clk),
                   .vid_rd_addr(vram_rd_addr),
                   .vid_rd_data(vram_rd_data),
                   .cpu_addr(13'b0),
                   .cpu_rd_data(),
                   .cpu_wr_data(8'b0),
                   .cpu_we(1'b0));

   wire       active_video = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
   wire       active_canvas = (h_count >= H_CANVAS_START &&
                               h_count < H_CANVAS_END &&
                               v_count >= V_CANVAS_START &&
                               v_count < V_CANVAS_END);
   wire       hsync_active = (h_count >= (H_VISIBLE + H_FRONT)) &&
              (h_count < (H_VISIBLE + H_FRONT + H_SYNC));
   wire       vsync_active = (v_count >= (V_VISIBLE + V_FRONT)) &&
              (v_count < (V_VISIBLE + V_FRONT + V_SYNC));

   always @(posedge clk) begin
      if (pixel_tick)
        clk_div <= 0;
      else
        clk_div <= clk_div + 1'b1;

      if (pixel_tick) begin
         if (h_count == H_TOTAL - 1) begin
            h_count <= 0;

            if (v_count == V_TOTAL - 1)
              v_count <= 0;
            else
              v_count <= v_count + 1;
         end else begin
            h_count <= h_count + 1;
         end

         vga_hsync <= ~hsync_active;
         vga_vsync <= ~vsync_active;

         // renderer
         if (active_video && active_canvas) begin
            // extract pixel
            // vram_rd_data % 8
            if (vram_rd_data[pixel_idx[2:0]]) begin
               vga_r <= 4'h0;
               vga_g <= 4'hF;
               vga_b <= 4'h0;
            end else begin
               vga_r <= 4'h0;
               vga_g <= 4'h0;
               vga_b <= 4'h0;
            end
         end else begin // black outside canvas
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
         end
      end // if (pixel_tick)
   end // always @ (posedge clk)


endmodule
