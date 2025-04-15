///////////////////////////////////////////
// csre.sv
//
// Written: David_Harris@hmc.edu 9 January 2021
// Modified: 
//
// Purpose: Control State Register for Zkr - Entropy Source
// 
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
// 
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file 
// except in compliance with the License, or, at your option, the Apache License version 2.0. You 
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the 
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
// either express or implied. See the License for the specific language governing permissions 
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

// NOTE: Maybe this can be merged with CSRM.sv... just a thought



module csre import cvw::*;  #(parameter cvw_t P) (
  input  logic              clk, reset,
  input  logic [1:0]        PrivilegeModeW,
  input  logic              CSREWriteM,
  input  logic [63:0]       MSECCFG_REGW,
  input  logic [11:0]       CSRAdrM,
  input  logic [P.XLEN-1:0] CSRWriteValM,
  output logic [P.XLEN-1:0] CSREReadValM,  
  output logic              IllegalCSREAccessM
);

  localparam SEED   = 12'h015;

  logic [P.XLEN-1:0]        SEED_REGW;
  logic [31:0]              NextSEED;
  // logic                     WriteSEED;
  // logic                     SeedEnable;
  
  // Write enables
  // assign WriteSEED = CSREWriteM & (CSRAdrM == SEED);

  // Write Values -- Entropy Source Instantiation
  // Note: new update to the entropy_top.sv makes the enable_i useless
  entropy_top #(.NUM_CELLS(9), .NUM_INV_START(9), .SIM_MODE(1)) entropy 
  (
    .clk(clk),
    .rst(rst),
    .enable_i(enable_i),
    .seed(NextSEED)
  );
  

  // Entropy Source Access Control via MSECCFG
  // VS, VU, and HS mode implementation later?
  always_comb begin
    // SEED CSR
    if (PrivilegeModeW == P.M_MODE)begin
      SEED_REGW = {{(P.XLEN-32){1'b0}}, NextSEED};
    end else if (P.U_SUPPORTED | P.S_SUPPORTED) begin
      IllegalCSREAccessM = 1'b0;
      case({PrivilegeModeW, MSECCFG_REGW[9:8]})
        4'b11xx: begin
                        SEED_REGW = {{(P.XLEN-32){1'b0}}, NextSEED};
        end
        4'b00x0: begin
                        SEED_REGW = '0;
                        IllegalCSREAccessM = 1'b1;
        end
        4'b00x1: begin
                        SEED_REGW = {{(P.XLEN-32){1'b0}}, NextSEED};
        end
        4'b010x: begin
                        SEED_REGW = '0;
                        IllegalCSREAccessM = 1'b1;
        end
        4'b011x: begin
                        SEED_REGW = {{(P.XLEN-32){1'b0}}, NextSEED};
        end
        default: begin
                        SEED_REGW = '0;
                        IllegalCSREAccessM = 1'b1;
        end
      endcase
    end

    // CSR Reads
    if (CSRAdrM == SEED)  CSREReadValM = SEED_REGW;
    else begin
                          CSREReadValM = '0; 
                          IllegalCSREAccessM = 1'b1;
    end
  end

  // // CSRs
  // flopenr #(32) SEEDreg(clk, reset, SeedEnable, NextSEED, SEED_REGW);

  // // CSR Reads
  // always_comb begin
  //   IllegalCSREAccessM = 1'b0;
  //   case (CSRAdrM) 
  //     SEED:       CSREReadValM = {{(P.XLEN-32){1'b0}}, SEED_REGW};
  //     default: begin
  //                 CSREReadValM = '0; 
  //                 IllegalCSREAccessM = 1'b1;
  //     end         
  //   endcase
  // end
endmodule
