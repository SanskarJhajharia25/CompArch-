module bcdtogray(b,g);
    input [3:0]b;
    output [3:0]g;
    assign g[3]=b[3];
    assign g[2]=b[2]^b[3];
    assign g[1]=b[2]^b[1];
    assign g[0]=b[0]^b[1];
endmodule

module testbench;
    reg [3:0]b;
    wire [3:0]g;
    bcdtogray o(b,g);
    initial begin
        $monitor("BCD=%b    Gray=%b",b,g);
        #0 b=4'b0000;
        #10 b=4'b0001;
        #20 b=4'b0010;
        #30 b=4'b0011;
        #40 b=4'b0100;
        #50 b=4'b0101;
        #60 b=4'b0110;
        #70 b=4'b0111;
        #80 b=4'b1000;
        #90 b=4'b1001;        
    end
endmodule

