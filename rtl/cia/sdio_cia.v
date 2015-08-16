/*
Distributed under the MIT license.
Copyright (c) 2015 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
 * Author: David McCoy (dave.mccoy@cospandesign.com)
 * Description: Common Interface Access (CIA)
 *  Controls many aspects of the card.
 *  Define values are values that do not change with implementation, for
 *    for example: CCCR version number and SDIO version number
 *  Parameter values change with every implementation, examples include
 *    Buffer depth and function numbers
 *
 * Changes:
 *  2015.13.09: Inital Commit
 */

`include "sdio_cia_defines.v"

module sdio_cia #(
  parameter                 BUFFER_DEPTH  = 8,
  parameter                 EN_8BIT_BUS   = 1'b0
)(
  input                     clk,    // SDIO PHY Clock
  input                     rst,

  input                     i_activate,
  input                     i_ready,
  output                    o_ready,
  output                    o_finished,
  input                     i_write_flag,
  input                     i_inc_addr,
  input         [17:0]      i_address,
  input                     i_data_stb,
  input         [17:0]      i_data_count,
  input         [7:0]       i_data_in,
  output        [7:0]       o_data_out,
  output                    o_data_stb,  //If reading, this strobes a new piece of data in, if writing strobes data out

  //FBR Interface
  output        [7:0]       o_fbr_select,
  output                    o_fbr_activate,
  output                    o_fbr_ready,
  output                    o_fbr_write_flag,
  output                    o_fbr_addr_in,
  output        [17:0]      o_fbr_address,
  output                    o_fbr_data_stb,
  output        [17:0]      o_fbr_data_count,
  output        [7:0]       o_fbr_data_in,

  input                     i_fbr1_finished,
  input                     i_fbr1_ready,
  input         [7:0]       i_fbr1_data_out,
  input                     i_fbr1_data_stb,

  input                     i_fbr2_finished,
  input                     i_fbr2_ready,
  input         [7:0]       i_fbr2_data_out,
  input                     i_fbr2_data_stb,

  input                     i_fbr3_finished,
  input                     i_fbr3_ready,
  input         [7:0]       i_fbr3_data_out,
  input                     i_fbr3_data_stb,

  input                     i_fbr4_finished,
  input                     i_fbr4_ready,
  input         [7:0]       i_fbr4_data_out,
  input                     i_fbr4_data_stb,

  input                     i_fbr5_finished,
  input                     i_fbr5_ready,
  input         [7:0]       i_fbr5_data_out,
  input                     i_fbr5_data_stb,

  input                     i_fbr6_finished,
  input                     i_fbr6_ready,
  input         [7:0]       i_fbr6_data_out,
  input                     i_fbr6_data_stb,

  input                     i_fbr7_finished,
  input                     i_fbr7_ready,
  input         [7:0]       i_fbr7_data_out,
  input                     i_fbr7_data_stb,


  //Function Configuration Interface
  output  reg   [7:0]       o_func_enable,
  input         [7:0]       i_func_ready,
  output  reg   [7:0]       o_func_int_enable,
  input         [7:0]       i_func_int_pending,
  output  reg               o_soft_reset,
  output  reg   [2:0]       o_func_abort_stb,
  output  reg               o_en_card_detect_n,
  output  reg               o_en_4bit_block_int, /* Enable interrupts durring 4-bit block data mode */
  input                     i_func_active,
  output  reg               o_bus_release_req_stb,
  output  reg   [3:0]       o_func_select,
  input                     i_data_txrx_in_progress_flag,
  input         [7:0]       i_func_exec_status,
  input         [7:0]       i_func_ready_for_data,
  output  reg   [15:0]      o_max_f0_block_size,

  output                    o_1_bit_mode,
  output                    o_4_bit_mode,
  output                    o_8_bit_mode,

  output                    o_sdr_12,
  output                    o_sdr_25,
  output                    o_sdr_50,
  output                    o_ddr_50,
  output                    o_sdr_104,

  output                    o_driver_type_a,
  output                    o_driver_type_b,
  output                    o_driver_type_c,
  output                    o_driver_type_d,
  output  reg               o_enable_async_interrupt
);

//Local Parameters

//Local Registers/Wires
wire                            cia_i_activate[0:`NO_SELECT_INDEX + 1];
wire                            cia_o_ready   [0:`NO_SELECT_INDEX + 1];
wire                            cia_o_finished[0:`NO_SELECT_INDEX + 1];
wire            [7:0]           cia_o_data_out[0:`NO_SELECT_INDEX + 1];
wire            [7:0]           cia_o_data_stb[0:`NO_SELECT_INDEX + 1];
reg             [3:0]           func_sel;

//submodules
sdio_cccr #(
  .BUFFER_DEPTH                 (BUFFER_DEPTH                 ),
  .EN_8BIT_BUS                  (EN_8BIT_BUS                  )
) cccr (
  .clk                          (clk                          ),
  .rst                          (rst                          ),

  .i_activate                   (cia_i_activate[`CCCR_INDEX]  ),
  .i_ready                      (i_ready                      ),
  .o_ready                      (cia_o_ready[`CCCR_INDEX]     ),
  .o_finished                   (cia_o_finished[`CCCR_INDEX]  ),
  .i_write_flag                 (i_write_flag                 ),
  .i_inc_addr                   (i_inc_addr                   ),
  .i_address                    (i_address                    ),
  .i_data_stb                   (i_data_stb                   ),
  .i_data_count                 (i_data_count                 ),
  .i_data_in                    (i_data_in                    ),
  .o_data_out                   (cia_o_data_out[`CCCR_INDEX]  ),
  .o_data_stb                   (cia_o_data_stb[`CCCR_INDEX]  ),

  .o_func_enable                (o_func_enable                ),
  .i_func_ready                 (i_func_ready                 ),
  .o_func_int_enable            (o_func_int_enable            ),
  .i_func_int_pending           (i_func_int_pending           ),
  .o_soft_reset                 (o_soft_reset                 ),
  .o_func_abort_stb             (o_func_abort_stb             ),
  .o_en_card_detect_n           (o_en_card_detect_n           ),
  .o_en_4bit_block_int          (o_en_4bit_block_int          ),
  .i_func_active                (i_func_active                ),
  .o_bus_release_req_stb        (o_bus_release_req_stb        ),
  .o_func_select                (o_func_select                ),
  .i_data_txrx_in_progress_flag (i_data_txrx_in_progress_flag ),
  .i_func_exec_status           (i_func_exec_status           ),
  .i_func_ready_for_data        (i_func_ready_for_data        ),
  .o_max_f0_block_size          (o_max_f0_block_size          ),

  .o_1_bit_mode                 (o_1_bit_mode                 ),
  .o_4_bit_mode                 (o_4_bit_mode                 ),
  .o_8_bit_mode                 (o_8_bit_mode                 ),

  .o_sdr_12                     (o_sdr_12                     ),
  .o_sdr_25                     (o_sdr_25                     ),
  .o_sdr_50                     (o_sdr_50                     ),
  .o_ddr_50                     (o_ddr_50                     ),
  .o_sdr_104                    (o_sdr_104                    ),

  .o_driver_type_a              (o_driver_type_a              ),
  .o_driver_type_b              (o_driver_type_b              ),
  .o_driver_type_c              (o_driver_type_c              ),
  .o_driver_type_d              (o_driver_type_d              ),
  .o_enable_async_interrupt     (o_enable_async_interrupt     )
);

//asynchronous logic

//Address Multiplexer
always @ (*) begin
  if (rst || o_soft_rest) begin
    func_sel      <=  `NO_SELECT_INDEX;
  end
  else begin
    if      ((i_address >= `CCCR_FUNCTION_START_ADDR)  && (i_address <= `CCCR_FUNCTION_END_ADDR )) begin
      //CCCR Selected
      func_sel      <=  `CCCR_INDEX;
    end
    else if ((i_address >= `FUNCTION_1_START_ADDR)     && (i_address <= `FUNCTION_1_END_ADDR    )) begin
      //Fuction 1 Sected
      func_sel      <=  `F1_INDEX;
    end
    else if ((i_address >= `FUNCTION_2_START_ADDR)     && (i_address <= `FUNCTION_2_END_ADDR    )) begin
      //Fuction 2 Sected
      func_sel      <=  `F2_INDEX;
    end
    else if ((i_address >= `FUNCTION_3_START_ADDR)     && (i_address <= `FUNCTION_3_END_ADDR    )) begin
      //Fuction 3 Sected
      func_sel      <=  `F3_INDEX;
    end
    else if ((i_address >= `FUNCTION_4_START_ADDR)     && (i_address <= `FUNCTION_4_END_ADDR    )) begin
      //Fuction 4 Sected
      func_sel      <=  `F4_INDEX;
    end
    else if ((i_address >= `FUNCTION_5_START_ADDR)     && (i_address <= `FUNCTION_5_END_ADDR    )) begin
      //Fuction 5 Sected
      func_sel      <=  `F5_INDEX;
    end
    else if ((i_address >= `FUNCTION_6_START_ADDR)     && (i_address <= `FUNCTION_6_END_ADDR    )) begin
      //Fuction 6 Sected
      func_sel      <=  `F6_INDEX;
    end
    else if ((i_address >= `FUNCTION_7_START_ADDR)     && (i_address <= `FUNCTION_7_END_ADDR    )) begin
      //Fuction 7 Sected
      func_sel      <=  `F7_INDEX;
    end
    else if ((i_address >= `MAIN_CIS_START_ADDR)       && (i_address <= `MAIN_CIS_END_ADDR      )) begin
      //Main CIS Region
      func_sel      <=  `MAIN_CIS_INDEX;
    end
    else begin
      func_sel      <=  `NO_SELECT_INDEX;
    end
  end
end


//All FPR Channel Specific interfaces are broght ito the multiplexer
assign  cia_o_finished[`F1_INDEX]         = i_fbr1_ready;
assign  cia_o_ready[`F1_INDEX]            = i_fbr1_ready;
assign  cia_o_data_out[`F1_INDEX]         = i_fbr1_data_out; 
assign  cia_o_data_stb[`F1_INDEX]         = i_fbr1_data_stb;

assign  cia_o_finished[`F2_INDEX]         = i_fbr2_ready;
assign  cia_o_ready[`F2_INDEX]            = i_fbr2_ready;
assign  cia_o_data_out[`F2_INDEX]         = i_fbr2_data_out; 
assign  cia_o_data_stb[`F2_INDEX]         = i_fbr2_data_stb;

assign  cia_o_finished[`F3_INDEX]         = i_fbr3_ready;
assign  cia_o_ready[`F3_INDEX]            = i_fbr3_ready;
assign  cia_o_data_out[`F3_INDEX]         = i_fbr3_data_out; 
assign  cia_o_data_stb[`F3_INDEX]         = i_fbr3_data_stb;

assign  cia_o_finished[`F4_INDEX]         = i_fbr4_ready;
assign  cia_o_ready[`F4_INDEX]            = i_fbr4_ready;
assign  cia_o_data_out[`F4_INDEX]         = i_fbr4_data_out; 
assign  cia_o_data_stb[`F4_INDEX]         = i_fbr4_data_stb;

assign  cia_o_finished[`F5_INDEX]         = i_fbr5_ready;
assign  cia_o_ready[`F5_INDEX]            = i_fbr5_ready;
assign  cia_o_data_out[`F5_INDEX]         = i_fbr5_data_out; 
assign  cia_o_data_stb[`F5_INDEX]         = i_fbr5_data_stb;

assign  cia_o_finished[`F6_INDEX]         = i_fbr6_ready;
assign  cia_o_ready[`F6_INDEX]            = i_fbr6_ready;
assign  cia_o_data_out[`F6_INDEX]         = i_fbr6_data_out; 
assign  cia_o_data_stb[`F6_INDEX]         = i_fbr6_data_stb;

assign  cia_o_finished[`F7_INDEX]         = i_fbr7_ready;
assign  cia_o_ready[`F7_INDEX]            = i_fbr7_ready;
assign  cia_o_data_out[`F7_INDEX]         = i_fbr7_data_out; 
assign  cia_o_data_stb[`F7_INDEX]         = i_fbr7_data_stb;


assign  cia_i_activate[func_sel]          = (func_sel == `CCCR_INDEX)     ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F1_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F2_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F3_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F4_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F5_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `F7_INDEX)       ? i_activate        : 1'b0;
assign  cia_i_activate[func_sel]          = (func_sel == `MAIN_CIS_INDEX) ? i_activate        : 1'b0;

assign  o_ready                           =  cia_o_ready[func_sel];
assign  o_finished                        =  cia_o_finished[func_sel];
assign  o_data_out                        =  cia_o_data_out[func_sel];
assign  o_data_stb                        =  cia_o_data_stb[func_sel];

assign  cia_o_ready   [`NO_SELECT_INDEX]  = 1'b0;
assign  cia_o_finished[`NO_SELECT_INDEX]  = 1'b1; //Always Done
assign  cia_o_data_out[`NO_SELECT_INDEX]  = 8'h0;
assign  cia_o_data_stb[`NO_SELECT_INDEX]  = 1'b0;

assign  o_fbr_select                      = func_sel;
assign  o_fbr_activate                    = i_activate;
assign  o_fbr_ready                       = i_ready;
assign  o_fbr_write_flag                  = i_write_flag;
assign  o_fbr_address                     = i_address;
assign  o_fbr_inc_addr                    = i_inc_addr;
assign  o_fbr_data_stb                    = i_data_stb;
assign  o_fbr_data_count                  = i_data_count;
assign  o_fbr_data_in                     = i_data_in;

endmodule
