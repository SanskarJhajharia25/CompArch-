//Sanskar Jhajharia
//2019A7PS0148P

module divider(inA,inB,quo,rem,CLOCK);//This is the code for the repeated division
    input [15:0]inA;
    input [7:0]inB;
    input CLOCK;
    output [15:0]quo;
    output [7:0]rem;
    wire [15:0]inAD, quod;
    wire [7:0]remD;
    assign quo=16'b0;
    assign rem=8'b0;
    assign inAD=inA;
    always @ (posedge CLOCK)
    begin
        if(inA<inB)
        begin
            remD={inA[7:0]};
        end
        else
        begin
            inAD=inAD-inB;
            quod=quod+1;
        end
    end

    assign rem=remD;
    assign quo=quod;
endmodule

module division (FLAG, qnt, rem, inA, inB, CLOCK, RESET, LOAD);
    input CLOCK, RESET, LOAD ;
    input [15:0]inA ;
    input [7:0]inB;
    output [2:0] FLAG;
    output [15:0] qnt; 
    output [7:0]rem; 

    always @ (posedge CLOCK or RESET)
    begin
        if(RESET) //The RESET Case
        begin
            qnt=16'b0000000000000000;
            rem=8'b00000000;
           assign FLAG=3'b000;
        end 

        else
        begin
            if(LOAD)
            begin

                if(inB==8'b0) //Special Case 1 of inB being 0;
                begin
                    qnt=16'b1111_1111_1111_1111;
                    rem=8'b1111_1111;
                    assign FLAG=3'b011;
                end

                else if(inB[7]==1'b0 & inB[6]==1'b0 & inB[5]==1'b0 & inB[4]==1'b0 & inB[3]==1'b0 & inB[2]==1'b0 & inB[1]==1'b0 & inB[0]==1'b1) //Special Case 2 where all divisor is 1. Hence all its except the last bit is 0 and the last bit is 1
                begin
                    qnt=inA;
                    rem=8'b0;
                    assign FLAG=3'b100;
                end

                else if(inB[0]==1'b0) //This is the Special Case 3 Where if a divisor is a power of 2, the LSB must be 0
                begin
                    assign FLAG=3'b101;
                end

                else if(inB > inA) //Special case 5
                begin
                    qnt=16'b0;
                    rem=inA;
                    assign FLAG=3'b111;
                end

            end
        end
    end
endmodule

module tb_division();
    reg [15:0]dividend;
    reg [7:0]divisor;
    reg CLOCK,RESET,LOAD;
    wire [15:0]quo;
    wire [7:0]rem;
    wire [2:0]FLAG;

    division d1(FLAG, quo, rem, dividend, divisor,CLOCK,RESET,LOAD);
    initial 
    begin
        forever
        #1 CLOCK=~CLOCK; //This is to enable clock to keep ticking at 2 ns
    end
    initial begin
        $monitor("a=&b  b=%b    quo=%b  rem=%b   FLAG=%b",dividend,divisor,quo,rem,FLAG);
    end
endmodule 