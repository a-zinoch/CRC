// 0 : CRC-32 / MPEG-2 -----------------------------------------------------------------------------
// CRC polynomial coefficients: x^32 + x^26 + x^23 + x^22 + x^16 + x^12 + x^11 + x^10 + x^8 + x^7 + x^5 + x^4 + x^2 + x + 1
//                              0x4C11DB7 (hex)
// CRC width:                   32 bits
// CRC shift direction:         left (big endian)
// Input word width:            32 bits
// -------------------------------------------------------------------------------------------------

// 1 : CRC-32Q -------------------------------------------------------------------------------------
// CRC polynomial coefficients: x^32 + x^31 + x^24 + x^22 + x^16 + x^14 + x^8 + x^7 + x^5 + x^3 + x + 1
//                              0x814141AB (hex)
// CRC width:                   32 bits
// CRC shift direction:         left (big endian)
// Input word width:            32 bits
// --------------------------------------------------------------------------------------------------

`include "../incs/defines.vh"

module CRC32_top(
    input        						clk_i,
    input        						rst_i,
    input        						edwr_l_i,
    input        						edwr_h_i,
    input       			 			sedrd_i,
    input  			[`PAW-1:0]  pr_adr_i,
    input				[31:0]  		src_i,
    output 		  [31:0]  		pr_src_o
);


/*
  `define CRC32_DI_ADDR     'h2A0
  `define CRC32_CI_ADDR     'h2A1
  `define CRC32_DO_ADDR     'h2A2
  `define CRC32_CountO_ADDR 'h2A3
*/

`define init_CRC32_MPEG2		'hFFFFFFFF
`define init_CRC32Q					'h00000000
`define adr_datInReg				`CRC_DATA_ADR
`define adr_confReg					`CRC_CONF_ADR 
`define adr_crcOutReg				`CRC_OUT_ADR
`define adr_countReg				`CRC_COUNT_ADR
`define CRC32_MPEG2					'b0
`define CRC32Q							'b1


reg [31:0] crc_init;
reg [31:0] dataIn_reg;
reg [31:0] crcOut_reg;
reg [31:0] count_reg;
reg [ 1:0] conf_reg;  // x(0/1) - chose CRC poly || (0/1)x - 1 Reset, 0 - enable 
reg dataAv;
reg polyChg;


wire [31:0] crc;
wire rd_crc_dat = pr_adr_i == `adr_crcOutReg && !sedrd_i;
wire rd_crc_cnt = pr_adr_i == `adr_countReg && !sedrd_i;

assign pr_src_o = rd_crc_dat ? crcOut_reg : rd_crc_cnt ? count_reg : 'bz;

CRC32_comb crc_i
	(
			.data_i(dataIn_reg)
		, .initCrc_i(crc_init)
		, .select_i(conf_reg[0])
		, .crc_o(crc)
  );


always @(posedge clk_i or negedge rst_i)
	begin
		if(~rst_i)
    	begin
				crc_init 		<= `init_CRC32_MPEG2;
				dataIn_reg 	<= 'b0;
				crcOut_reg  <= 'b0;
				conf_reg 		<= 'b0;
				dataAv 			<= 'b0;
				count_reg 	<= 'b0;
				polyChg 		<= 'b0;
   		end
    else
    	begin
				if (conf_reg[1])
					begin
						dataIn_reg 	<= 'b0;
						conf_reg[1] <= 'b0;
						dataAv 			<= 'b0;
						count_reg 	<= 'b0;
						polyChg 		<= 'b0;
	    			case(conf_reg[0])
							`CRC32_MPEG2 : 	crc_init <= `init_CRC32_MPEG2;
							`CRC32Q : 			crc_init <= `init_CRC32Q;
							default : 			crc_init <= `init_CRC32_MPEG2;
	    			endcase
					end
				else if (polyChg)
					begin
	    			case(conf_reg[0])
							`CRC32_MPEG2 :
								begin
							    crc_init 	<= `init_CRC32_MPEG2;
							    count_reg <= 'b0;
							    polyChg 	<= 'b0;
								end
							`CRC32Q :
								begin
								    crc_init 	<= `init_CRC32Q;
								    count_reg <= 'b0;
								    polyChg 	<= 'b0;
								end
							default : 
								begin
							   		crc_init 	<= `init_CRC32_MPEG2;
							    	count_reg <= 'b0;
							    	polyChg 	<= 'b0;
								end
	    			endcase
					end
				else if (dataAv) 
					begin
			    	crc_init 		<= crc;
			    	crcOut_reg 	<= crc;
			    	count_reg 	<= count_reg + 1'b1;
			    	dataAv 			<= 'b0;
					end
				case(pr_adr_i)
	    		`adr_datInReg :
	    			begin
							if (~edwr_l_i) dataIn_reg[15:0] 	<= src_i[15:0];
							if (~edwr_h_i) dataIn_reg[31:16] 	<= src_i[31:16];
							dataAv <= (~edwr_l_i | ~edwr_h_i);
	    			end
			    `adr_confReg:
				    begin
							if (~edwr_l_i) 
								begin
							    polyChg <= conf_reg[0] != src_i[0];
							    conf_reg[1:0] <= src_i[1:0];
								end
				    end
			endcase
    end
	end
endmodule
