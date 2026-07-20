// ---------------------------------------------------------------------------
// tb_soc.v  --  Simulation testbench for the Space Invaders CPU subsystem
// ---------------------------------------------------------------------------
//
// WHAT IS A TESTBENCH?
//   A testbench is ordinary Verilog that is NEVER put on the FPGA. Its only
//   job is to (1) create the input signals a real board would provide -- a
//   clock and a reset -- and (2) watch the outputs so we can tell whether the
//   design behaves correctly. Think of it as a virtual bench with a clock
//   generator and a logic analyzer wired to your chip.
//
//   The module below has NO ports. That is the signature of a top-level
//   testbench: it is self-contained. Everything (clk, rst, the DUT) lives
//   inside it.
//
// WHAT WE ARE TESTING
//   We instantiate the exact same internal wiring as fpga_top.v, but WITHOUT
//   the Zynq PS7 block (system_wrapper) -- that block can't be simulated here
//   and only supplies the clock on real hardware. We also leave out the VGA
//   module: on hardware VGA generates the two frame interrupts, but here we
//   generate them ourselves so the CPU's interrupt-driven draw code can run
//   without waiting for a full 60 Hz video frame.
//
//   "DUT" = Device Under Test = the collection of modules we care about:
//   light8080 CPU + adapter + memmap + rom + ram + vram + interrupt.
//
// THE KEY PROBE
//   The light8080 presents a read address for ONE cycle, then the data must be
//   valid the NEXT cycle (synchronous memory). memmap.v selects ROM/RAM/VRAM
//   combinationally from the *current* address. So on the data cycle, the
//   region-select can be looking at the wrong address. To catch this we keep
//   our own copy of the ROM ("shadow_rom") and, for every ROM read, we compare
//   the byte the CPU actually received against the byte that SHOULD be there.
//   A mismatch means the bus/memmap timing is broken.
// ---------------------------------------------------------------------------

`timescale 1ns / 1ps

module tb_soc;

   // -------------------------------------------------------------------------
   // 1. Clock and reset generation (this is what the "bench" provides)
   // -------------------------------------------------------------------------
   reg clk = 1'b0;

   // 50 MHz clock = 20 ns period => toggle every 10 ns.
   // This "always #10 clk = ~clk" runs forever and is the heartbeat of the sim.
   always #10 clk = ~clk;

   // Reset. On the real board fpga_top holds rst high for 255 cycles at power
   // up (the por_count). We do the same idea but shorter: hold rst high for a
   // handful of cycles, then release it. The light8080 only needs reset high
   // for 1 cycle, so this is plenty.
   reg rst = 1'b1;

   // -------------------------------------------------------------------------
   // 2. All the internal nets -- copied 1:1 from fpga_top.v
   // -------------------------------------------------------------------------
   // VGA <-> VRAM video read port (unused here; we tie the address to 0)
   wire [12:0] vga_vram_rd_addr = 13'b0;
   wire [7:0]  vga_vram_rd_data;

   // Memory map <-> VRAM CPU port
   wire [12:0] cpu_vram_addr;
   wire [7:0]  cpu_vram_rd_data;
   wire [7:0]  cpu_vram_wr_data;
   wire        cpu_vram_we;

   // Memory map <-> ROM
   wire [12:0] rom_addr;
   wire [7:0]  rom_data;

   // Memory map <-> RAM
   wire [9:0]  ram_addr;
   wire [7:0]  ram_rd_data;
   wire [7:0]  ram_wr_data;
   wire        ram_we;

   // CPU core <-> adapter
   wire        l80_vma;
   wire        l80_io;
   wire        l80_rd;
   wire        l80_wr;
   wire [7:0]  l80_data_out;
   wire [7:0]  l80_data_in;
   wire [15:0] l80_addr_out;
   wire        l80_inta;
   wire        l80_fetch;
   wire        l80_halt;
   wire        l80_inte;

   // adapter <-> memmap
   wire [15:0] cpu_addr;
   wire [7:0]  cpu_rd_data;
   wire [7:0]  cpu_wr_data;
   wire        cpu_we;

   // interrupt <-> CPU / adapter.  int1/int2 are driven by US (the TB).
   reg         vga_int1 = 1'b0;
   reg         vga_int2 = 1'b0;
   wire        l80_intr;
   wire [7:0]  irq_opcode;

   // -------------------------------------------------------------------------
   // 3. Instantiate the DUT (same connections as fpga_top, minus PS7 and VGA)
   // -------------------------------------------------------------------------
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
                   .vram_rd_addr(vga_vram_rd_addr),
                   .vram_rd_data(vga_vram_rd_data),
                   .cpu_addr(cpu_vram_addr),
                   .cpu_rd_data(cpu_vram_rd_data),
                   .cpu_wr_data(cpu_vram_wr_data),
                   .cpu_we(cpu_vram_we));

   interrupt int_inst (.clk(clk),
                       .rst(rst),
                       .int1(vga_int1),
                       .int2(vga_int2),
                       .inta(l80_inta),
                       .intr(l80_intr),
                       .irq_opcode(irq_opcode));

   light8080 l8080 (.clk(clk),
                    .reset(rst),
                    .addr_out(l80_addr_out),
                    .vma(l80_vma),
                    .io(l80_io),
                    .rd(l80_rd),
                    .wr(l80_wr),
                    .data_in(l80_data_in),
                    .data_out(l80_data_out),
                    .fetch(l80_fetch),
                    .inta(l80_inta),
                    .inte(l80_inte),
                    .intr(l80_intr),
                    .halt(l80_halt));

   light8080_adapter l8080_adapter (.vma(l80_vma),
                                    .io(l80_io),
                                    .rd(l80_rd),
                                    .wr(l80_wr),
                                    .data_out(l80_data_out),
                                    .addr_out(l80_addr_out),
                                    .data_in(l80_data_in),
                                    .inta(l80_inta),
                                    .memmap_cpu_addr(cpu_addr),
                                    .memmap_cpu_wr_data(cpu_wr_data),
                                    .memmap_cpu_we(cpu_we),
                                    .memmap_cpu_rd_data(cpu_rd_data),
                                    .irq_opcode(irq_opcode));

   // -------------------------------------------------------------------------
   // 4. Our own reference copy of the ROM, so we can check what the CPU reads.
   //    This array is NOT part of the design -- it's the "known-good answer
   //    key" the testbench grades against.
   // -------------------------------------------------------------------------
   reg [7:0] shadow_rom [0:8191];
   initial $readmemh("space_invaders.hex", shadow_rom);

   // -------------------------------------------------------------------------
   // 5. Waveform dump for GTKWave (optional, but very useful to "see" signals)
   // -------------------------------------------------------------------------
   initial begin
      $dumpfile("tb_soc.vcd");
      $dumpvars(0, tb_soc);   // 0 = dump this module and everything below it
   end

   // -------------------------------------------------------------------------
   // 6. Reset sequence + overall time limit
   // -------------------------------------------------------------------------
   initial begin
      rst = 1'b1;
      repeat (10) @(posedge clk);   // hold reset for 10 clocks
      rst = 1'b0;
      $display("[%0t] reset released", $time);
   end

   // -------------------------------------------------------------------------
   // 7. Generate the two frame interrupts ourselves.
   //    On hardware the VGA module pulses int1 mid-frame and int2 at the end
   //    of the frame. We fake that with short periodic pulses so the game's
   //    interrupt handler (which is where it draws) actually gets to run.
   // -------------------------------------------------------------------------
   initial begin
      @(negedge rst);               // wait until reset is released
      forever begin
         repeat (20000) @(posedge clk);
         vga_int1 <= 1'b1; @(posedge clk); vga_int1 <= 1'b0;
         repeat (20000) @(posedge clk);
         vga_int2 <= 1'b1; @(posedge clk); vga_int2 <= 1'b0;
      end
   end

   // -------------------------------------------------------------------------
   // 8. THE MONITOR -- the heart of the testbench.
   //
   //    light8080 read timing (from the core's own datasheet):
   //      cycle N   : addr_out valid, vma & rd asserted  (address phase)
   //      cycle N+1 : data_in must be valid, CPU latches it  (data phase)
   //
   //    So we remember the address requested this cycle, and one cycle later
   //    we look at the data the CPU received and compare it to shadow_rom.
   // -------------------------------------------------------------------------
   reg        rd_pending = 1'b0;    // a memory read was requested last cycle
   reg [15:0] rd_addr    = 16'h0;   // the address that was requested
   reg        rd_fetch   = 1'b0;    // was that read an opcode fetch?
   reg        rd_inta    = 1'b0;    // was the CPU in interrupt-ack when it asked?

   integer    fetch_count = 0;
   integer    mismatch_count = 0;
   integer    vram_write_count = 0;
   reg        seen_inte = 1'b0;

   // helper: is a 16-bit CPU address in the ROM region (after mirroring)?
   function is_rom;
      input [15:0] a;
      reg   [15:0] m;
      begin
         m = a & 16'h3FFF;         // memmap discards the top 2 bits
         is_rom = (m < 16'h2000);  // 0x0000-0x1FFF is ROM
      end
   endfunction

   always @(posedge clk) begin
      if (!rst) begin

         // -- (a) check the read that was requested on the PREVIOUS edge -----
         if (rd_pending && rd_inta == 1'b0 && is_rom(rd_addr)) begin
            if (l80_data_in !== shadow_rom[(rd_addr & 16'h3FFF)]) begin
               mismatch_count = mismatch_count + 1;
               $display("[%0t] *** BUS MISMATCH at addr=0x%04h : CPU got 0x%02h, ROM has 0x%02h  (fetch=%0d)",
                        $time, rd_addr, l80_data_in,
                        shadow_rom[(rd_addr & 16'h3FFF)], rd_fetch);
            end
         end

         // -- (b) trace opcode fetches (first 300, so the log stays readable) -
         if (l80_fetch && fetch_count < 300) begin
            $display("[%0t] fetch #%0d  PC=0x%04h  opcode=0x%02h%s",
                     $time, fetch_count, l80_addr_out, l80_data_in,
                     l80_inta ? "  (interrupt)" : "");
         end
         if (l80_fetch)
           fetch_count = fetch_count + 1;

         // -- (c) milestone: the CPU wrote to video RAM (it's drawing!) ------
         if (cpu_vram_we) begin
            vram_write_count = vram_write_count + 1;
            if (vram_write_count <= 5 || (vram_write_count % 1000 == 0))
              $display("[%0t] VRAM write #%0d : vram_addr=0x%04h data=0x%02h",
                       $time, vram_write_count, cpu_vram_addr, cpu_vram_wr_data);
         end

         // -- (d) milestone: interrupts got enabled (EI executed) -----------
         if (l80_inte && !seen_inte) begin
            seen_inte <= 1'b1;
            $display("[%0t] interrupts ENABLED by CPU (first EI)", $time);
         end

         // -- (e) record this cycle's read request for checking next cycle ---
         rd_pending <= l80_vma && l80_rd;
         rd_addr    <= l80_addr_out;
         rd_fetch   <= l80_fetch;
         rd_inta    <= l80_inta;
      end
   end

   // -------------------------------------------------------------------------
   // 9. Periodic heartbeat so you can see forward progress, and a final
   //    summary when the run ends.
   // -------------------------------------------------------------------------
   initial begin
      @(negedge rst);
      forever begin
         repeat (20000) @(posedge clk);
         $display("[%0t] ...running: fetches=%0d  vram_writes=%0d  mismatches=%0d  (last PC=0x%04h)",
                  $time, fetch_count, vram_write_count, mismatch_count, l80_addr_out);
      end
   end

   initial begin
      // total simulated time budget. #1 unit = 1 ns (from `timescale).
      // 4,000,000 ns = 4 ms = 200,000 clock cycles at 50 MHz.
      #4000000;
      $display("=====================================================");
      $display("SIM DONE @ %0t", $time);
      $display("  opcode fetches : %0d", fetch_count);
      $display("  VRAM writes    : %0d", vram_write_count);
      $display("  bus mismatches : %0d", mismatch_count);
      $display("  interrupts EN  : %0d", seen_inte);
      if (mismatch_count > 0)
        $display("  RESULT: FAIL -- CPU read wrong bytes off the bus.");
      else if (vram_write_count == 0)
        $display("  RESULT: SUSPECT -- CPU never wrote to VRAM (game not drawing).");
      else
        $display("  RESULT: CPU executed and drew to VRAM.");
      $display("=====================================================");
      $finish;
   end

endmodule
