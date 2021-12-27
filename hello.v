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
    reg a,b,c;
    wire d,e;
    adder ader(d,e,a,b,c);
    initial
        begin
            $monitor(,$time," a=%b , b=%b, c=%b,   sum=%b, carry=%b" ,a,b,c,d,e);
            #0 a=1'b1; b=1'b1; c=1'b1;
            #10 a=1'b1; b=1'b1; c=1'b0;
            #20 a=1'b1; b=1'b0; c=1'b1;
            #30 a=1'b1; b=1'b0; c=1'b0;
            #40 a=1'b0; b=1'b1; c=1'b1;
            #50 a=1'b0; b=1'b1; c=1'b0;
            #60 a=1'b0; b=1'b0; c=1'b1;
            #70 a=1'b0; b=1'b0; c=1'b0;
          
             $finish;
        end
endmodule