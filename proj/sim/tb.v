`timescale 1ns / 1ps

module tb;

    reg        clk;
    reg        rst;
    reg  [7:0] data_in;
    reg  [2:0] shift;
    reg        data_we;
    reg        shift_we;

    wire [7:0] data_out;

    shifter dut (
        .clk      (clk),
        .rst      (rst),
        .data_in  (data_in),
        .shift    (shift),
        .data_we  (data_we),
        .shift_we (shift_we),
        .data_out (data_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task write_data;
        input [7:0] value;
        begin
            @(negedge clk);
            data_in = value;
            data_we = 1'b1;

            @(negedge clk);
            data_we = 1'b0;
        end
    endtask

    task write_shift;
        input [2:0] value;
        begin
            @(negedge clk);
            shift = value;
            shift_we = 1'b1;

            @(negedge clk);
            shift_we = 1'b0;
        end
    endtask

    task check_output;
        input [7:0] expected;
        begin
            #1;

            if (data_out !== expected) begin
                $display(
                    "FAIL: shift=%0d output=%02h expected=%02h",
                    shift,
                    data_out,
                    expected
                );
            end else begin
                $display(
                    "PASS: shift=%0d output=%02h",
                    shift,
                    data_out
                );
            end
        end
    endtask

    initial begin
        rst      = 1'b1;
        data_in  = 8'h00;
        shift    = 3'd0;
        data_we  = 1'b0;
        shift_we = 1'b0;

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        write_data(8'hAA);
        write_data(8'hCC);

        write_shift(3'd0);
        check_output(8'hCC);

        write_shift(3'd1);
        check_output(8'h99);

        write_shift(3'd2);
        check_output(8'h32);

        write_shift(3'd3);
        check_output(8'h65);

        write_shift(3'd4);
        check_output(8'hCA);

        write_shift(3'd5);
        check_output(8'h95);

        write_shift(3'd6);
        check_output(8'h2A);

        write_shift(3'd7);
        check_output(8'h55);

        $display("Testbench complete.");
        $finish;
    end

endmodule
