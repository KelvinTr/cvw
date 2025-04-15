module entropy_top #(parameter NUM_CELLS=11, parameter NUM_INV_START=11, parameter SIM_MODE=1) (
  input  logic        clk,
  input  logic        rst,
  input  logic        enable_i,
  output logic [31:0] seed);

  logic        valid_o;
  logic [1:0]  error_o;
  logic        initialization;
  logic [7:0]  data_o;
  logic [15:0] seed_temp;
  logic        en_test;

  entropy #(.NUM_CELLS(NUM_CELLS), .NUM_INV_START(NUM_INV_START), .SIM_MODE(SIM_MODE)) dut 
    ( .clk(clk),
      .rst(rst),
      .enable_i(enable_i),
      .data_o(data_o),
      .valid_o(valid_o),
      .error_o(error_o));

  typedef enum logic [1:0] {BIST, WAIT, ES16, DEAD} statetype;
  statetype state, nextstate;

  // state register
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      state <= BIST;
    end else state <= nextstate;
  end

  always @(posedge valid_o, posedge rst) begin
    if (rst) begin
      seed_temp = 16'b0;
      initialization <= 1'b1;
      en_test <= 1'b0;
    end
    en_test <= 1'b1;
    seed_temp = {seed_temp[7:0], data_o};
    if ((initialization == 1'b0) && (valid_o == 1'b1)) initialization = 1'b1;
    else if ((initialization == 1'b1) && (valid_o == 1'b1)) initialization = 1'b0;
    if (valid_o == 1'b1) en_test = 1'b0;
  end

  // next state logic
  always_comb begin
    case (state)
      BIST: 
        begin
          seed <= 32'b0;
          if (error_o == 2'b01) nextstate <= BIST;
          else if (valid_o == 1'b0) nextstate <= WAIT;
          else if ((valid_o == 1'b1) && initialization > 1'b0) nextstate <= ES16;
          // Add some on-demand tests?
        end
      WAIT: 
        begin
          seed <= 32'h4000_0000;
          if (error_o == 2'b01) nextstate <= BIST;
          else if (error_o == 2'b10) nextstate <= WAIT;
          else if ((valid_o == 1'b1) && initialization == 1'b0) nextstate <= ES16;
        end
      ES16: 
        begin
          if ((valid_o == 1'b1) && initialization == 1'b1) seed <= {2'b10, 14'b0, seed_temp};
          else seed <= seed;

          if (error_o == 2'b01) nextstate <= BIST;
          else if (error_o == 2'b10)  nextstate <= WAIT;
          else nextstate <= ES16;
          
        end
    //   DEAD:          //NOT USED FOR NOW. Difficult to implement dead state currently due to hardware fault detection
    //     begin

    //     end
      default: 
        begin
          seed <= 32'b0;
          nextstate <= BIST;
        end
    endcase
  end
endmodule