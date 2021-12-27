module adder(s,cout,a,b,cin);
    output s,cout;
    input a,b,cin;
    wire d,e,f;
    xor a1(d,a,b);
    xor a2(s,d,cin);
    and a3(e,a,b);
    and a4(f,d,cin);
    or a5(cout, e,f);
   // not n1(c,d);
endmodule


module testbench;
    reg a0,a1,a2,a3,b0,b1,b2,b3;
    wire cc,c0,c1,c2,c3,s0,s1,s2,s3;
    //cc=1'b0;
    adder ader1(s0,c0,a0,b0,1'b0);
    adder ader2(s1,c1,a1,b1,c0);
    adder ader3(s2,c2,a2,b2,c1);
    adder ader4(s3,c3,a3,b3,c2);
    initial
        begin
            $monitor(,$time," a=%b%b%b%b , b=%b%b%b%b, sum=%b%b%b%b%b" ,a3,a2,a1,a0,b3,b2,b1,b0,c3,s3,s2,s1,s0);
            #0 a3=1'b1; a2=1'b0; a1=1'b0; a0=1'b0;b3=1'b0;b2=1'b1;b1=1'b0;b0=1'b0;
            #10 a3=1'b0; a2=1'b1; a1=1'b1; a0=1'b1;b3=1'b0;b2=1'b1;b1=1'b1;b0=1'b0;
            // #30 a=1'b1; b=1'b0; c=1'b0;
            // #40 a=1'b0; b=1'b1; c=1'b1;
            // #50 a=1'b0; b=1'b1; c=1'b0;
            // #60 a=1'b0; b=1'b0; c=1'b1;
            // #70 a=1'b0; b=1'b0; c=1'b0;
          
             $finish;
        end
endmodule