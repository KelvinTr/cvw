module ring_osc_gen #(parameter SIM_MODE = 1) (
  input logic clk, 
  input logic rst,
  input logic en_i,
  input logic latch_in,
  input logic sreg,
  input logic inv_in,
  output logic latch,
  output logic inv_out);

  always @(*) begin
    if (rst == 1'b1)  latch = 1'b0;

    if (en_i == 1'b0) latch = 1'b0;
    else if (sreg == 1'b0) latch = latch_in;
    else latch = inv_out;

    @(posedge clk) begin
      inv_out = ~inv_in;
      if (sreg == 1'b1) latch = inv_out;
      // Physical code removed since there is no way for testing currently
    end

  end
  
endmodule