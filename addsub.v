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

module addsub(a,b,m,s,v);
    input [3:0] a;
    input [3:0] b;
    input m;
    output v;output [3:0] s;

    wire [3:0] c;
    wire [3:0] b1;
    assign b1[0]=b[0]^m;
    assign b1[1]=b[1]^m;
    assign b1[2]=b[2]^m;
    assign b1[3]=b[3]^m;
    
    
    FADDER f1(s[0],c[0],a[0],b1[0],m);
    FADDER f2(s[1],c[1],a[1],b1[1],c[0]);
    FADDER f3(s[2],c[2],a[2],b1[2],c[1]);
    FADDER f4(s[3],c[3],a[3],b1[3],c[2]);
    xor x1(v,c[3],c[2]);
endmodule

module testbench;
    reg [3:0]x;
    reg [3:0]y;
    reg m;
    wire [3:0]s;
    wire v;
   // FADDER fl(s,c,x,y,z);
   addsub aa(x,y,m,s,v);
    initial
        $monitor(,$time,"   x=%b,  y=%b,   m=%b,   s=%b,   v=%b",x,y,m,s,v);
        initial
        begin
            #0 x=4'b0100;y=4'b0011;m=1'b0;
            #4 x=4'b0100;y=4'b0011;m=1'b1;
            #4 x=4'b0101;y=4'b0011;m=1'b0;
            #4 x=4'b0111;y=4'b0011;m=1'b1;
            #4 x=4'b0100;y=4'b0101;m=1'b0;
            #4 x=4'b1000;y=4'b0011;m=1'b1;
            #4 x=4'b1100;y=4'b0101;m=1'b1;
            #4 x=4'b1100;y=4'b0011;m=1'b0;

            
            end
endmodule