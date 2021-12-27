module fpdiv(AbyB, DONE, EXCEPTION, InputA, InputB, CLOCK, RESET); //Newton-Raphson  Algorithm

	input CLOCK, RESET; // Active High
	input [31:0] InputA, InputB;
	output [31:0] AbyB;
	output DONE; //Holds whether the operation is completed or not
	output [1:0] EXCEPTION; //A 2bit exception controller as per the question given
	
	// Intermediate Variables
	reg [31:0] ExSol;
	reg [1:0] EXCEPTION;
	reg DONE, force_output;
	wire sign;
	wire [7:0] shift, exponent_a;
	wire [31:0] divisor, op_a, Intermediate_X0;
	wire [31:0] Iteration_X0, Iteration_X1, Iteration_X2, Iteration_X3;
	wire [31:0] answer, denominator, op_a_change, sol_exponent;
	
	assign sign = InputA[31] ^ InputB[31]; //If one is positive and one is negative, the final answer must preserve the same
	assign shift = 8'd126 - InputB[30:23]; //Exponent of B is shifted
	assign divisor = {1'b0,8'd126,InputB[22:0]};
	assign denominator = divisor;
	assign exponent_a = InputA[30:23] + shift; //Exponent of A into consideration
	assign op_a = {InputA[31],exponent_a,InputA[22:0]};
	assign op_a_change = op_a;
	assign sol_exponent = (InputA[30:23] - InputB[30:23]); //The difference of the exponents of the two numbers will be the non-normalised exponent of the asnswer. That is stored here
	
	// Reciprocal Block: 
	Multiplication x0(32'hC00B_4B4B,divisor,,,,Intermediate_X0);
	Addition_Subtraction X0(Intermediate_X0,32'h4034_B4B5,1'b0,,Iteration_X0);
	Iteration X1(Iteration_X0,divisor,Iteration_X1);
	Iteration X2(Iteration_X1,divisor,Iteration_X2);
	Iteration X3(Iteration_X2,divisor,Iteration_X3);
	Multiplication END(Iteration_X3,op_a,,,,answer);	// A * 1/B

	assign AbyB = force_output ? ExSol : {sign,answer[30:0]};
	
	// Exception Handling
    // 00: Divide by 0
    // 01: Underflow
    // 10: Overflow
    // 11: Invalid
	always @* 
	begin
		EXCEPTION = 2'bxx;
		DONE = 1'b0;
		force_output = 1'b0;
		ExSol = 32'bx;
		
		
		if(RESET) // If the RESET BIT is set to 1. Positive synchronous
		begin
			EXCEPTION = 2'bxx;
			DONE = 1'b0;
			force_output = 1'b0;
			ExSol = 32'bx;
		end

        // 00: Divide Normal by Zero
		else if ((0 < InputA[30:23] && 255 > InputA[30:23]) && InputB[31:0] == 32'h00000000) 
		begin
			EXCEPTION = 2'b00;
            ExSol[31] = 0;
            ExSol[30:23] = 255;
            ExSol[22:0] = 0;
			force_output = 1'b1;
			DONE = 1'b1;
		end

		// 11: Invalid Operands
        // NaN occurs when the exponent is 255 that is [30:23]=255 and the mantissa is ... thus [22:0]=0
		else if (((InputA[30:23] == 255) && (InputA[22:0] != 23'b0)) || ((InputB[30:23] == 255) && (InputB[22:0] != 23'b0))) // A NaN or B NaN (r= NaN)
		begin 
			EXCEPTION = 2'b11;
            ExSol[31] = 0;
            ExSol[30:23] = 255;
            ExSol[22] = 1;
            ExSol[21:0] = 0;
			force_output = 1'b1;
			DONE = 1'b1;
		end
		else if (((InputA[30:23] == 255) && (InputA[22:0] == 23'b0)) && ((InputB[30:23] == 255) && (InputB[22:0] == 23'b0))) // A Inf and B Inf (r= NaN)
		begin
			EXCEPTION = 2'b11;
			ExSol[31] = 0;
            ExSol[30:23] = 255;
            ExSol[22] = 1;
            ExSol[21:0] = 0;
            force_output = 1'b1;
			DONE = 1'b1;
		end
		else if (((InputA[30:23] == 255) && (InputA[22:0] == 23'b0))) // A Inf and B normal
			begin
			if (InputB[31:0] == 32'h00000000) // B Zero (r= NaN)
			begin
				EXCEPTION = 2'b11;
                ExSol[31] = 0;
                ExSol[30:23] = 255;
                ExSol[22] = 1;
                ExSol[21:0] = 0;
				force_output = 1'b1;
				DONE = 1'b1;
			end
			else // B normal (r= inf)
			begin
				EXCEPTION = 2'b11;
                ExSol[31] = 0;
                ExSol[30:23] = 255;
                ExSol[22:0] = 0;
				force_output = 1'b1;
				DONE = 1'b1;
			end
			end 
		else if (((InputB[30:23] == 255) && (InputB[22:0] == 23'b0))) // B Inf (r= Zero)
		begin
			EXCEPTION = 2'b11;
			ExSol[31:0] = 0;
			force_output = 1'b1;
			DONE = 1'b1;
		end
		else if ((InputA[31:0] == 32'h00000000) && (InputB[31:0] == 32'h00000000)) // A Zero and B Zero (r= NaN)
		begin
			EXCEPTION = 2'b11;
            ExSol[31] = 0;
            ExSol[30:23] = 255;
            ExSol[22] = 1;
            ExSol[21:0] = 0;
			force_output = 1'b1;
			DONE = 1'b1;
		end
		// 10: Overflow		
		else if ((sol_exponent[8] == 0) && (sol_exponent) > 127) // Overflow
		begin	
			EXCEPTION = 2'b10;
			ExSol[31] = 0;
            ExSol[30:23] = 255;
            ExSol[22:0] = 0;force_output = 1'b1;
			DONE = 1'b1;
		end
		// 01: Underflow
		else if ((sol_exponent[8] == 1) && (sol_exponent < -127)) // Subnormal Numbers
		begin
			EXCEPTION = 2'b01;
			ExSol[31:0] = 0;
			force_output = 1'b1;
			DONE = 1'b1;
		end
		else 
		begin
			DONE = 1'b1;
		end
	end	
endmodule

// Iteration Module (implements X(i+1) = X(i)*(2-DX(i))
module Iteration(left_op,right_op,answer); 
	input [31:0] left_op;
	input [31:0] right_op;
	output [31:0] answer;
	wire [31:0] Intermediate_Value1,Intermediate_Value2;
	
	Multiplication M1(left_op,right_op,,,,Intermediate_Value1);//32'h4000_0000 -> 2.
	Addition_Subtraction A1(32'h4000_0000,{1'b1,Intermediate_Value1[30:0]},1'b0,,Intermediate_Value2);
	Multiplication M2(left_op,Intermediate_Value2,,,,answer);
endmodule

// Addtion-Subtraction Module
module Addition_Subtraction(a_op,b_op,AddBar_Sub,Exception,result);// ADD:0, SUB: 1
	input [31:0] a_op,b_op;
	input AddBar_Sub;			  
	output Exception;
	output [31:0] result; 
	
	wire operation_sub_addBar, Comp_enable, output_sign;
	wire [31:0] op_a,op_b;
	wire [23:0] significand_a,significand_b, significand_b_add_sub, significand_sub_complement;
	wire [7:0] exponent_diff, exponent_sub, exponent_b_add_sub;
	wire [24:0] significand_add, significand_sub, subtraction_diff; 
	wire [30:0] add_sum, sub_diff;

	assign {Comp_enable,op_a,op_b} = (a_op[30:0] < b_op[30:0]) ? {1'b1,b_op,a_op} : {1'b0,a_op,b_op};	//Compare A, B
	assign exp_a = op_a[30:23];
	assign exp_b = op_b[30:23];

	assign Exception = (&op_a[30:23]) | (&op_b[30:23]);
	assign output_sign = AddBar_Sub ? Comp_enable ? !op_a[31] : op_a[31] : op_a[31] ;
	assign operation_sub_addBar = AddBar_Sub ? op_a[31] ^ op_b[31] : ~(op_a[31] ^ op_b[31]);

	assign significand_a = (|op_a[30:23]) ? {1'b1,op_a[22:0]} : {1'b0,op_a[22:0]};//Assigining significand values according to Hidden Bit == Significand Bit
	assign significand_b = (|op_b[30:23]) ? {1'b1,op_b[22:0]} : {1'b0,op_b[22:0]};

	assign exponent_diff = op_a[30:23] - op_b[30:23];//Evaluating Exponent Difference
	assign significand_b_add_sub = significand_b >> exponent_diff;//Shifting significand_b according to exponent_diff: pperand_b is smaller.
	assign exponent_b_add_sub = op_b[30:23] + exponent_diff; 
	assign perform = (op_a[30:23] == exponent_b_add_sub);//Checking exponents are same or not
	
	// Addtion Block
	assign significand_add = (perform & operation_sub_addBar) ? (significand_a + significand_b_add_sub) : 25'd0; 
	assign add_sum[22:0] = significand_add[24] ? significand_add[23:1] : significand_add[22:0];
	assign add_sum[30:23] = significand_add[24] ? (1'b1 + op_a[30:23]) : op_a[30:23];
	
	// Subtraction Block
	assign significand_sub_complement = (perform & !operation_sub_addBar) ? ~(significand_b_add_sub) + 24'd1 : 24'd0 ; 
	assign significand_sub = perform ? (significand_a + significand_sub_complement) : 25'd0;
	priority_encoder pe(significand_sub,op_a[30:23],subtraction_diff,exponent_sub);
	assign sub_diff[30:23] = exponent_sub;
	assign sub_diff[22:0] = subtraction_diff[22:0];
	
	assign result = Exception ? 32'b0 : ((!operation_sub_addBar) ? {output_sign,sub_diff} : {output_sign,add_sum});// Check for Exception

endmodule

// Multiplication Module
module Multiplication(a_op, b_op, Exception, Overflow, Underflow, result);
	input [31:0] a_op;
	input [31:0] b_op;
	output Exception,Overflow,Underflow;
	output [31:0] result;
	
	wire sign,product_round,normalised,zero;
	wire [8:0] exponent,sum_exponent;
	wire [22:0] product_mantissa;
	wire [23:0] op_a,op_b;
	wire [47:0] product,product_normalised; //Total bits = 24 + 24 = 48

	assign sign = a_op[31] ^ b_op[31];
	assign Exception = (&a_op[30:23]) | (&b_op[30:23]);// Setting flag as 1 if either of the operands is 255
	
	assign op_a = (|a_op[30:23]) ? {1'b1,a_op[22:0]} : {1'b0,a_op[22:0]};//Assigining significand values according to Hidden Bit.
	assign op_b = (|b_op[30:23]) ? {1'b1,b_op[22:0]} : {1'b0,b_op[22:0]};
	assign product = op_a * op_b;			
	assign product_round = |product_normalised[22:0];  //Last 22 bits OR'ed for rounding operation.
	assign normalised = product[47] ? 1'b1 : 1'b0;	
	assign product_normalised = normalised ? product : product << 1;//Assigning Normalised value based on 48th bit
	
	assign product_mantissa = product_normalised[46:24] + {21'b0,(product_normalised[23] & product_round)};//Mantissa value
	assign zero = Exception ? 1'b0 : (product_mantissa == 23'd0) ? 1'b1 : 1'b0;
	assign sum_exponent = a_op[30:23] + b_op[30:23];
	assign exponent = sum_exponent - 8'd127 + normalised;

	assign Overflow = ((exponent[8] & !exponent[7]) & !zero) ; //(Exponent >255) ... Overflow Condtion
	assign Underflow = ((exponent[8] & exponent[7]) & !zero) ? 1'b1 : 1'b0;	// (Sum of exponent < 127) ... Underflow Comdition
    //First Check if there is an exception that has occured. If not then check for it being zero or not. Then check for overflow or underflow. If none of these cases, then assign the value to the result value
	assign result = Exception ? 32'd0 : zero ? {sign,31'd0} : Overflow ? {sign,8'hFF,23'd0} : Underflow ? {sign,31'd0} : {sign,exponent[7:0],product_mantissa}; 
endmodule

// Priority Encoder Module
module priority_encoder(significand,exp_a,Significand,exp_sub);
	input [24:0] significand;
	input [7:0] exp_a;
	output reg [24:0] Significand;
	output [7:0] exp_sub;
	reg [4:0] shift;

	always @(significand)
	begin
		casex (significand)
			25'b1_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx :	begin                       //24'h800000
														Significand = significand;
														shift = 5'd0;
													end
			25'b1_01xx_xxxx_xxxx_xxxx_xxxx_xxxx : 	begin					    //24'h400000	
														Significand = significand << 1;
														shift = 5'd1;
													end

			25'b1_001x_xxxx_xxxx_xxxx_xxxx_xxxx : 	begin					     // 24'h200000	
														Significand = significand << 2;
														shift = 5'd2;
													end

			25'b1_0001_xxxx_xxxx_xxxx_xxxx_xxxx : 	begin 					    // 24'h100000		
														Significand = significand << 3;
														shift = 5'd3;
													end

			25'b1_0000_1xxx_xxxx_xxxx_xxxx_xxxx : 	begin						// 24'h080000
														Significand = significand << 4;
														shift = 5'd4;
													end

			25'b1_0000_01xx_xxxx_xxxx_xxxx_xxxx : 	begin					    // 24'h040000	
														Significand = significand << 5;
														shift = 5'd5;
													end

			25'b1_0000_001x_xxxx_xxxx_xxxx_xxxx : 	begin						// 24'h020000
														Significand = significand << 6;
														shift = 5'd6;
													end

			25'b1_0000_0001_xxxx_xxxx_xxxx_xxxx : 	begin						// 24'h010000
														Significand = significand << 7;
														shift = 5'd7;
													end

			25'b1_0000_0000_1xxx_xxxx_xxxx_xxxx : 	begin						// 24'h008000
														Significand = significand << 8;
														shift = 5'd8;
													end

			25'b1_0000_0000_01xx_xxxx_xxxx_xxxx : 	begin						// 24'h004000
														Significand = significand << 9;
														shift = 5'd9;
													end

			25'b1_0000_0000_001x_xxxx_xxxx_xxxx : 	begin						// 24'h002000
														Significand = significand << 10;
														shift = 5'd10;
													end

			25'b1_0000_0000_0001_xxxx_xxxx_xxxx : 	begin						// 24'h001000
														Significand = significand << 11;
														shift = 5'd11;
													end

			25'b1_0000_0000_0000_1xxx_xxxx_xxxx : 	begin						// 24'h000800
														Significand = significand << 12;
														shift = 5'd12;
													end

			25'b1_0000_0000_0000_01xx_xxxx_xxxx : 	begin						// 24'h000400
														Significand = significand << 13;
														shift = 5'd13;
													end

			25'b1_0000_0000_0000_001x_xxxx_xxxx : 	begin						// 24'h000200
														Significand = significand << 14;
														shift = 5'd14;
													end

			25'b1_0000_0000_0000_0001_xxxx_xxxx  : 	begin						// 24'h000100
														Significand = significand << 15;
														shift = 5'd15;
													end

			25'b1_0000_0000_0000_0000_1xxx_xxxx : 	begin						// 24'h000080
														Significand = significand << 16;
														shift = 5'd16;
													end

			25'b1_0000_0000_0000_0000_01xx_xxxx : 	begin						// 24'h000040
														Significand = significand << 17;
														shift = 5'd17;
													end

			25'b1_0000_0000_0000_0000_001x_xxxx : 	begin						// 24'h000020
														Significand = significand << 18;
														shift = 5'd18;
													end

			25'b1_0000_0000_0000_0000_0001_xxxx : 	begin						// 24'h000010
														Significand = significand << 19;
														shift = 5'd19;
													end

			25'b1_0000_0000_0000_0000_0000_1xxx :	begin						// 24'h000008
														Significand = significand << 20;
														shift = 5'd20;
													end

			25'b1_0000_0000_0000_0000_0000_01xx : 	begin						// 24'h000004
														Significand = significand << 21;
														shift = 5'd21;
													end

			25'b1_0000_0000_0000_0000_0000_001x : 	begin						// 24'h000002
														Significand = significand << 22;
														shift = 5'd22;
													end

			25'b1_0000_0000_0000_0000_0000_0001 : 	begin						// 24'h000001
														Significand = significand << 23;
														shift = 5'd23;
													end

			25'b1_0000_0000_0000_0000_0000_0000 : 	begin						// 24'h000000
														Significand = significand << 24;
														shift = 5'd24;
													end
			default : 	begin
							Significand = (~significand) + 1'b1;
							shift = 5'd0;
						end

		endcase
	end
	assign exp_sub = exp_a - shift;
endmodule


// Test Bench
module tb_fp_div();
 	reg clk = 0;
	reg [31:0] a_op;
	reg [31:0] b_op;
	reg reset;
	wire [31:0] result;
	wire [1:0] Exception;
	reg [31:0] Expected_result;
	
	fpdiv myFPDivider(result,,Exception,a_op, b_op, clk,reset);
			
	initial begin
	$display ("The Group Members are:");
	$display ("********************************************");
	$display ("2019A7PS0090P Yash Munjal");
	$display ("2019A7PS0148P Sanskar Jhajharia");
	$display ("********************************************");
	end

    initial begin
	$display ("Design Description :-");
    $display ("********************************************");
	$display ("Single Cycle Implementation of divider that works on the Positive edge of the clock. There is an absence of guard bits in our code.");
	$display ("********************************************");
	end


	
	always 
		#5 clk = ~clk;
	
	always@(*)
		$monitor($time, " A = %h, B = %h, Exception = %b, A/B (Calculated) = %h,  Expected Result = %h",a_op, b_op, Exception, result, Expected_result);
	
	always @(posedge clk) 
	begin

			#6 $display("Case 1: Normal");
			//#6 a_op = 32'h40a00000; b_op = 32'h40000000; Expected_result = 32'h40200000;
            #6 a_op = 32'h41200000; b_op = 32'h40A00000; Expected_result = 32'h40000000; $display("     10/5 = 2");
			
			#6 $display("Case 2: Divide by Zero");
			#6 a_op = 32'h40400000; b_op = 32'h00000000; Expected_result = 32'h7f800000;$display("		3 / Zero = Inf");
			
			#6 $display("Case 3: Invalid Operands");
			#6 a_op = 32'h7fc00000; b_op = 32'h7fc00000; Expected_result = 32'h7fc00000;$display("		A or B = NaN");
			#6 a_op = 32'h7f800000; b_op = 32'h7f800000; Expected_result = 32'h7fc00000;$display("		Inf / Inf = NaN");
			#6 a_op = 32'h7f800000; b_op = 32'h00000000; Expected_result = 32'h7fc00000;$display("		Inf / Zero = NaN");
			#6 a_op = 32'h7f800000; b_op = 32'h40400000; Expected_result = 32'h7f800000;$display("		Inf / 3 = Inf");
			#6 a_op = 32'h40400000; b_op = 32'h7f800000; Expected_result = 32'h00000000;$display("		3 / Inf = Zero");
			#6 a_op = 32'h00000000; b_op = 32'h00000000; Expected_result = 32'h7fc00000;$display("		Zero / Zero = NaN");
				
			#6 $display("Case 4: Underflow/Overflow");			
			#6 a_op = 32'h00195399; b_op = 32'h7f7fffff; Expected_result = 32'h00000000;$display("		Underflow (Subnormal number)");// Smallest Positive Subnormal / 2 ~ Zero [Underflow]
			#6 a_op = 32'h7f7fffff; b_op = 32'h00195387; Expected_result = 32'h7f800000;$display("		Overflow (Subnormal number)");// Largest Positive Normal / Smallest Positive Normal ~ Inf [Overflow]
			
			# 60 $finish;	
	end
endmodule