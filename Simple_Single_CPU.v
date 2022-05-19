//Subject:     CO project 2 - Simple Single CPU
//--------------------------------------------------------------------------------
//Version:     1
//--------------------------------------------------------------------------------
//Writer:      
//----------------------------------------------
//Date:        
//----------------------------------------------
//Description: 
//--------------------------------------------------------------------------------
module Simple_Single_CPU(
        clk_i,
		rst_i
		);
		
//I/O port
input         clk_i;
input         rst_i;

//Internal Signles
wire [31:0] pc_in;
wire [31:0] pc_out;

wire [31:0] pc_next;

wire [31:0] instr;

wire [1:0]  RegDst;
wire [4:0]  WriteRegDst; 

wire [31:0] RDdata;
wire [31:0] RSdata;
wire [31:0] RTdata;
wire 		RegWrite;

wire [1:0]  ALUop;
wire 		ALUSrc;
wire 		Branch;
wire [1:0]  BranchType;
wire        Jump; // No [1:0]
wire 		MemRead;
wire 		MemWrite;
wire [1:0]  MemtoReg;

wire [3:0]  ALUCtrl;
wire 		Jaddr;

wire [31:0] extended;

wire [31:0] ALUSrcData;

wire [31:0] result;
wire 		zero;

wire [31:0] MemData;

wire [31:0] pc_branch;

wire [31:0] shifted;

wire [31:0] pc_Bch;

wire [31:0] JumpAddr;
wire [31:0] pc_J;

wire 		Bch;

//Greate componentes
ProgramCounter PC(
        .clk_i(clk_i),      
	    .rst_i (rst_i),     
	    .pc_in_i(pc_in) ,   
	    .pc_out_o(pc_out) 
	    );
	
Adder Adder1( // pc = pc + 4
        .src1_i(pc_out),     
	    .src2_i(32'd4),     
	    .sum_o(pc_next)    
	    );
	
Instr_Memory IM(
        .pc_addr_i(pc_out),  
	    .instr_o(instr)    
	    );

MUX_4to1 #(.size(5)) Mux_Write_Reg( // Write Register Destination, 0: I-type / 1: R-type / 2: jal
		.data0_i(instr[20:16]),
		.data1_i(instr[15:11]),
		.data2_i(5'd31),
		.data3_i(5'd31),
		.select_i(RegDst),
		.data_o(WriteRegDst)
);
		
Reg_File Registers(
        .clk_i(clk_i),      
	    .rst_i(rst_i) ,     
        .RSaddr_i(instr[25:21]) ,  
        .RTaddr_i(instr[20:16]) ,  
        .RDaddr_i(WriteRegDst) ,  
        .RDdata_i(RDdata)  , 
        .RegWrite_i (RegWrite),
        .RSdata_o(RSdata) ,  
        .RTdata_o(RTdata)   
        );
	
Decoder Decoder(
        .instr_op_i(instr[31:26]),
	    .RegWrite_o(RegWrite),
	    .ALU_op_o(ALUop),
		.ALUSrc_o(ALUSrc),
		.RegDst_o(RegDst),
		.Branch_o(Branch),
		.BranchType_o(BranchType),
		.Jump_o(Jump),
		.MemRead_o(MemRead),
		.MemWrite_o(MemWrite),
		.MemtoReg_o(MemtoReg)
	    );

ALU_Ctrl AC(
        .funct_i(instr[5:0]),   
        .ALUOp_i(ALUop),   
        .ALUCtrl_o(ALUCtrl),
        .jr_o(Jaddr)
        );
	
Sign_Extend SE(
        .data_i(instr[15:0]),
        .data_o(extended)
        );

MUX_2to1 #(.size(32)) Mux_ALUSrc( // RT data or immediate
        .data0_i(RTdata),
        .data1_i(extended),
        .select_i(ALUSrc),
        .data_o(ALUSrcData)
        );	
		
ALU ALU(
        .src1_i(RSdata),
	    .src2_i(ALUSrcData),
	    .ctrl_i(ALUCtrl),
	    .result_o(result),
		.zero_o(zero)
	    );
	
Data_Memory Data_Memory(
	.clk_i(clk_i),
	.addr_i(result),
	.data_i(RTdata),
	.MemRead_i(MemRead),
	.MemWrite_i(MemWrite),
	.data_o(MemData)
	);
	
MUX_4to1 #(.size(32)) RDdata_Src( //source of RDdata, 0: from ALU / 1: lw / 2: immediate / 3: store pc
		.data0_i(result),
		.data1_i(MemData),
		.data2_i(extended),
		.data3_i(pc_next),
		.select_i(MemtoReg),
		.data_o(RDdata)
);

Shift_Left_Two_32 Shifter(
        .data_i(extended),
        .data_o(shifted)
        ); 
	
Adder Adder2( //  pc = pc + b
        .src1_i(pc_next),     
	    .src2_i(shifted),     
	    .sum_o(pc_branch)      
	    );		

MUX_4to1 #(.size(1)) Branch_Type( // branch type, 0: beq / 1: bgt / 2: bge / 3: bne
		.data0_i(zero),
		.data1_i(~(result[31] & zero)),
		.data2_i(~result[31]),
		.data3_i(~zero),
		.select_i(BranchType),
		.data_o(Bch)
);

MUX_2to1 #(.size(32)) Mux_PC_Branch( // use branch?
        .data0_i(pc_next),
        .data1_i(pc_branch),
        .select_i(Branch & Bch),
        .data_o(pc_Bch)
);

Shift_Left_Two_32 Shifter_jump( // j address
        .data_i({6'd0, instr[25:0]}),
        .data_o(JumpAddr)
);

MUX_2to1 #(.size(32)) Mux_PC_Jump( // use jump?
		.data0_i(pc_Bch),
        .data1_i({pc_next[31:28], JumpAddr[27:0]}),
        .select_i(Jump),
        .data_o(pc_J)
);

MUX_2to1 #(.size(32)) Mux_PC_Jr( // use jr?
		.data0_i(pc_J),
        .data1_i(RSdata),
        .select_i(Jaddr),
        .data_o(pc_in)
);

endmodule
