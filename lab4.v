module mux2to1(input1, input2, input3, select, out);
    input input1, input2,input3;
    input [1:0] select;
    output out;
    wire not_sel1,not_sel2, a1,a2;
    not (not_sel1,select[0]);
    not (not_sel2,select[1]);
    and (a1,input1,not_sel1,not_sel2);
    and (a2,input2,select[0],not_sel2);
    and (a3,input3,select[1],not_sel1);
    or (out,a1,a2,a3);
endmodule

module bit8_2to1mux(out,sel,in1,in2,in3);
    input [7:0] in1,in2,in3;
    output [7:0] out;
    input [1:0] sel;
    genvar j; 
    //this  is  the  variable  that  is  be  used  in  the  generate block
    generate      
        for   (j=0;   j<8;j=j+1)   
            begin:   mux_loop  //mux_loop is the name of the loop
                mux2to1 m1(in1[j],in2[j],in3[j],sel,out[j]); //mux2to1 is instantiated every time it is called
            end
    endgenerate
endmodule

module bit32_2to1mux(out,sel,in1,in2,in3);
    input [31:0] in1, in2, in3;
    output [31:0] out;
    input [1:0]sel;
    bit8_2to1mux b1(out[31:24],sel,in1[31:24],in2[31:24],in3[31:24]);
    bit8_2to1mux b2(out[23:16],sel,in1[23:16],in2[23:16],in3[23:16]);
    bit8_2to1mux b3(out[15:8],sel,in1[15:8],in2[15:8],in3[15:8]);
    bit8_2to1mux b4(out[7:0],sel,in1[7:0],in2[7:0],in3[7:0]);
endmodule

// module tb_32mux;
//     reg [31:0] a,b,c;
//     reg [1:0] select;
//     wire [31:0] out;
//     bit32_2to1mux b1(out,select,a,b,c);
//     initial 
//     begin
//         $monitor("a=%h      b=%h     c=%h     select=%b    answer=%h",a,b,c,select,out);
//         a=32'ha7a7a7a7;
//         b=32'hffffffff;
//         c=32'h00000000;
//         select=2'b00;
//         #5    select=2'b01;
//         #10     select = 2'b10;

//     end
// endmodule

module binverter1bit(out,sel,in1);
    input in1,sel;
    output out;
    assign out=sel? ~in1 : in1;
    
endmodule

module binverter(out,sel,in1);
    input [31:0] in1;
    output [31:0] out;
    input sel;
    // wire [31:0] w;
    //assign w=32'b00000000_00000000_00000000_00000000;
    genvar j; 
    //this  is  the  variable  that  is  be  used  in  the  generate block
    generate      
        for   (j=0;   j<32;j=j+1)   
            begin:   mux_loop  //mux_loop is the name of the loop
                binverter1bit m1(out[j],sel,in1[j]); //mux2to1 is instantiated every time it is called
            end
    endgenerate
    
endmodule

module bit32AND (out,in1,in2);
    input [31:0] in1,in2;
    output [31:0] out;
    assign {out}=in1 & in2;
endmodule

module bit32OR (out,in1,in2);
    input [31:0] in1,in2;
    output [31:0] out;
    assign {out}=in1 | in2;
endmodule

module DECODER(d0,d1,d2,d3,d4,d5,d6,d7,x,y,z);
    input x,y,z;
    output d0,d1,d2,d3,d4,d5,d6,d7;
    wire x0,y0,z0;
    not n1(x0,x);
    not n2(y0,y);
    not n3(z0,z);
    and a0(d0,x0,y0,z0);
    and a1(d1,x0,y0,z);
    and a2(d2,x0,y,z0);
    and a3(d3,x0,y,z);
    and a4(d4,x,y0,z0);
    and a5(d5,x,y0,z);
    and a6(d6,x,y,z0);
    and a7(d7,x,y,z);
endmodule

module FADDER(s,c,x,y,z);
    input x,y,z;
    wire d0,d1,d2,d3,d4,d5,d6,d7;
    output s,c;
    DECODER dec(d0,d1,d2,d3,d4,d5,d6,d7,x,y,z);
    assign s= d1 | d2 | d4 | d7,
    c = d3 | d5 | d6 | d7;
endmodule

module addsub(a,b,m,s,c);
    input [31:0] a;
    input [31:0] b;
    input m;
    output c;
    output [31:0] s;
    wire [31:0] c1;
    FADDER ff(s[0],c1[0],a[0],b[0],m);
    genvar j; 
    //this  is  the  variable  that  is  be  used  in  the  generate block
    generate      
        for   (j=1;   j<=31;j=j+1)   
            begin:  adder  //mux_loop is the name of the loop
                FADDER m1(s[j], c1[j],a[j],b[j],c1[j-1]); //mux2to1 is instantiated every time it is called
            end
    endgenerate
    or o1(c,c1[31],1'b0);
endmodule

module alu(a,b,Binvert,Operation,Result,CarryOut);
    input [31:0] a,b;
    input Binvert,Carrryin;
    input [1:0] Operation;
    output [31:0] Result;
    output CarryOut;
    wire [31:0] wiand, wior, wadd, w1;

    binverter b1(w1,Binvert,b);
    
    bit32AND and1(wiand,a,b);
    bit32OR or1(wior,a,b);
    addsub add1(a,w1,Binvert,wadd,CarryOut);

    bit32_2to1mux bb(Result,Operation,wiand,wior,wadd);
endmodule

module  MainControlUnit(RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp0, ALUOp1, Op);
  output  RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, ALUOp0, ALUOp1;
  input [5:0] Op;
  wire  RFormat, LW, SW, BEQ;
  assign  RFormat = (~Op[5])&(~Op[4])&(~Op[3])&(~Op[2])&(~Op[1])&(~Op[0]);
  assign  LW = (Op[5])&(~Op[4])&(~Op[3])&(~Op[2])&(Op[1])&(Op[0]);
  assign  SW = (Op[5])&(~Op[4])&(Op[3])&(~Op[2])&(Op[1])&(Op[0]);
  assign  BEQ = (~Op[5])&(~Op[4])&(~Op[3])&(Op[2])&(~Op[1])&(~Op[0]);
  assign  RegDst = RFormat;
  assign  ALUSrc = LW | SW;
  assign  MemToReg = LW;
  assign  RegWrite = RFormat | LW;
  assign  MemRead = LW;
  assign  MemWrite = SW;
  assign  Branch = BEQ;
  assign  ALUOp0 = RFormat;
  assign  ALUOp1 = BEQ;
endmodule

module  ALUControlUnit(Op, Func, ALUOp0, ALUOp1);
  input [5:0] Func;
  input ALUOp0, ALUOp1;
  output  [2:0] Op;
  assign  Op[0] = ALUOp1 & (Func[3] | Func[0]);
  assign  Op[1] = (~ALUOp1) | (~Func[2]);
  assign  Op[2] = ALUOp0 | (ALUOp1 & Func[1]);
endmodule

module tbALU;
    reg Binvert;
    reg [1:0] Operation;
    reg [31:0] a,b;
    wire [31:0] Result;
    wire CarryOut;
    alu a1(a,b,Binvert,Operation,Result,CarryOut);
    //bit32OR a1(Result, a ,b);
    initial
    begin
        $monitor("a=%h      b=%h           answer=%h",a,b,Result);
        a=32'ha5a5a5a5;
        b=32'h5a5a5a5a;
       Operation=2'b00;
        Binvert=1'b0;
        //must perform AND resulting in zero
        #100 Operation=2'b01; //OR
        #100 Operation=2'b10; //ADD
        #100 Binvert=1'b1;//SUB
        #200 $finish;
        // 
        end
        endmodule





// module tb_addsub;
//     reg [31:0] INP1;
//     reg INP3;
//     wire [31:0] out;
//     //or (INP3,1'b0,1'b0);
//     binverter M1(out,INP3,INP1);
    
//     initial
        
//         begin
//             $monitor(,$time,"   a= %b     b=%b     ",INP1,out);
//             INP1=32'b00000000_00000000_00000000_00000010;
//             INP3=1'b0;
//             #5 INP3=1'b1;
//             #100 $finish;
//         end
// endmodule



// module tb_addsub;
//     reg [31:0] INP1, INP2;
//     reg INP3;
//     reg [1:0]SEL;
//     wire out1;
//     wire [31:0] out;
//     //or (INP3,1'b0,1'b0);
//     addsub M1(INP1,INP2,INP3,out,out1);
    
//     initial
        
//         begin
//             $monitor(,$time,"a= %b     b=%b     carry=%b   cout=%b",INP1,INP2,out,out1);
//             INP1=32'b00000000_00000000_00000000_00000010;
//             INP2=32'b01010101_01010101_01010101_01010101;
//             INP3=1'b0;
//         end
// endmodule

// module tb_8bit2to1mux;
//     reg [31:0] INP1, INP2, INP3;
//     reg [1:0]SEL;
//     wire [31:0] out;
//     bit32_2to1mux M1(out,SEL,INP1,INP2,INP3);
    
//     initial
        
//         begin
//             $monitor(,$time,"a= %b     b=%b     c=%b    selected=%b",INP1,INP2,INP3,out);
//             INP1=32'b10101010_10101010_10101010_10101010;
//             INP2=32'b01010101_01010101_01010101_01010101;
//             INP3=32'b11111111_11111111_11111111_11111111;
//             SEL=2'b00;
//             #100 SEL=2'b01;
//             #200 SEL=2'b10;
//             #1000 
//             $finish;
//         end
// endmodule