`include "../incs/defines.vh"
`include "../incs/timescale.vh"
module CRC32_test();

reg     CLK, RST, EDWR_L, EDWR_H, SEDRD;
reg     [31:0]  SRC;
reg     [7:0]   PR_ADR;
wire    [31:0]  PR_SRC;
                        
CRC32_top CRC32_1_i
(
    .clk_i(CLK)
  , .pr_adr_i(PR_ADR)
  , .edwr_l_i(EDWR_L)
  , .edwr_h_i(EDWR_H)
  , .sedrd_i(SEDRD)
  , .rst_i(RST)
  , .src_i(SRC)
  , .pr_src_o(PR_SRC)
);


always	#10 CLK <= ~CLK;

task RESET;
begin
  RST     <= 'b0;
  PR_ADR  <= 'b0;
  EDWR_L  <= 'b1;
  EDWR_H  <= 'b1;
  SRC     <= 'hF0F0F0F0;
  @(posedge CLK)
  @(posedge CLK)
  @(posedge CLK)
  RST     <= 'b1;
end
endtask


task RESET_LGT;
begin
  @(posedge CLK)
  PR_ADR  <= `CRC_CONF_ADR;
  EDWR_L  <= 'b0;
  SRC     <= 'h00000002;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  EDWR_L  <= 'b1;
  SRC     <= 'h0;
end
endtask

task CHG_POLY(input poly);
begin
  @(posedge CLK)
  PR_ADR  <= `CRC_CONF_ADR;
  EDWR_L  <= 'b0;
  SRC     <= poly;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  EDWR_L  <= 'b1;
  SRC     <= 'h0;
end
endtask

task CRC ( input [31:0] data);
begin
  @(posedge CLK)
  PR_ADR  <= `CRC_DATA_ADR;
  //PR_ADR <= 'b0;
  EDWR_L  <= 'b0;
  EDWR_H  <= 'b0;
  SRC     <= data;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  EDWR_L  <= 'b1;
  EDWR_H  <= 'b1;
  SRC     <= 'bz;
  @(posedge CLK)
  PR_ADR  <= `CRC_OUT_ADR;
  SEDRD   <= 'b0;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  SEDRD   <= 'b1;
end
endtask

task CRC_SEQ ( input [31:0] data);
begin
  @(posedge CLK)
  PR_ADR  <= `CRC_DATA_ADR;
  //PR_ADR <= 'b0;
  EDWR_L  <= 'b0;
  EDWR_H  <= 'b0;
  SRC     <= data;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  EDWR_L  <= 'b1;
  EDWR_H  <= 'b1;
  SRC     <= 'bz;
end
endtask

task GET_COUNT;
begin
  @(posedge CLK)
  PR_ADR  <= `CRC_COUNT_ADR;
  SEDRD   <= 'b0;
  @(posedge CLK)
  PR_ADR  <= 'b0;
  SEDRD   <= 'b1;
end
endtask

initial                                                
begin     
  $display("Running testbench");
  CLK     <= 'b0;
  RST     <= 'b1;
  SRC     <= 'h0;
  SEDRD   <= 'b1;
  EDWR_L  <= 'b1;
  EDWR_H  <= 'b1;
  RESET();
  CRC_SEQ('h1f1f1f1f);
  CRC_SEQ('h0);
  CRC_SEQ('h11111111);
  CRC('hffffffff);
  GET_COUNT();
  CHG_POLY('b1);
  CRC_SEQ('h1f1f1f1f);
  CRC_SEQ('h0);
  CRC_SEQ('h11111111);
  CRC('hffffffff);
  GET_COUNT();
  RESET_LGT();
  CHG_POLY('b0);
  CRC('h0);
  GET_COUNT();
  CHG_POLY('b1);
  CRC('h0);
  GET_COUNT();
end                                                    


endmodule
