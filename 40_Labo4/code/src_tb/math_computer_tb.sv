/******************************************************************************
Project Math_computer

File : math_computer_tb.sv
Description : This module implements a test bench for a simple
              mathematic calculator.
              Currently it is far from being efficient nor useful.

Author : Y. Thoma
Team   : REDS institute

Date   : 13.04.2017

| Modifications |--------------------------------------------------------------
Ver    Date         Who    Description
1.0    13.04.2017   YTA    First version

******************************************************************************/

`include "math_computer_macros.sv"
`include "math_computer_itf.sv"

module math_computer_tb#(integer testcase = 0,
                         integer errno = 0);

    // Déclaration et instanciation des deux interfaces
    math_computer_input_itf input_itf();
    math_computer_output_itf output_itf();

    // Seulement deux signaux
    logic      clk = 0;
    logic      rst;

    // instanciation du compteur
    math_computer dut(clk, rst, input_itf, output_itf);

    // génération de l'horloge
    always #5 clk = ~clk;

    // clocking block
    default clocking cb @(posedge clk);
        output #3ns rst,
               a            = input_itf.a,
               b            = input_itf.b,
               c            = input_itf.c,
               input_valid  = input_itf.valid,
               output_ready = output_itf.ready;
        input  input_ready  = input_itf.ready,
               result       = output_itf.result,
               output_valid = output_itf.valid;
    endclocking


    //Number of errors detected
    int errors = 0;
    //**************************************************************
    //
    //**************************************************************
    class random_input;
        rand logic[`DATASIZE-1:0] a;
        rand logic[`DATASIZE-1:0] b;
        rand logic[`DATASIZE-1:0] c;

        constraint a_dist{
            a dist{
                // 1/2 of the time the value will be comprise
                // between 0 to 9
                [0:9] :=1,

                // 1/2 o the time the value will be comprise between 10 and
                // 2 power by DATASIZE (max value).
                [10:(2**`DATASIZE-1)] :=1
            };
        }

        //constraint type if "A (a>b)" then do "B (c<1000)"
        constraint c_range{
            (a>b) -> (c<1000);
        }

        constraint ab_constr{
            // one of both a and b need to be pair number to do that put bit0
            //to "1" for a or b . With that bit0 of a and b will never be "0"
            a[0] || b[0];
        }

        //a need to be randomize first and after b and finally c
        constraint order {solve a before b; solve b before c;}
    endclass


    //**************************************************************
    // Task for the testcase0
    //**************************************************************
    task test_case0();
        $display("Let's start first test case");
        cb.a <= 0;
        cb.b <= 0;
        cb.c <= 0;
        cb.input_valid  <= 0;
        cb.output_ready <= 0;

        ##1;
        // Le reset est appliqué 5 fois d'affilée
        repeat (5) begin
            cb.rst <= 1;
            ##1 cb.rst <= 0;
            ##10;
        end

        repeat (10) begin
            cb.input_valid <= 1;
            cb.a <= 1;
            ##1;
            ##($urandom_range(100));
            cb.output_ready <= 1;
        end
    endtask

    //**************************************************************
    // Task for the testcase1
    //**************************************************************
    task test_case1();
        $display("Let's start second test case");

        // Reset all the DUT signal
        cb.a <= 0;
        cb.b <= 0;
        cb.c <= 0;
        cb.input_valid  <= 0;
        cb.output_ready <= 0;
        ##1; //Wait 1 clock

        //applied reset
        cb.rst <= 1;
        ##1;
        cb.rst <= 0;
        ##10;

        //Test 10 result
        repeat(10) begin

            //Generation of random data for a,b and c
            random_input data;
            //Create new instance of data
            data = new();
            //Randomize all the variable "rand" in data
            assert(data.randomize()) else $error("No solution for data.randomize");

            cb.a <= data.a;
            cb.b <= data.b;
            cb.c <= data.c;

            ##1;

            //Display the three variable a,b and c
            $display("a is %d", cb.a);
            $display("b is %d", cb.b);
            $display("c is %d", cb.c);

            //Set the valid to indicate valid data and set input_ready
            //to indicate that it's ready for the result
            cb.input_valid  <= 1;
            cb.output_ready <= 1;
            ##10;


            //Wait the signal output_valid to indicate a result
            wait(cb.output_valid == 1)
            $display("Result is %d", cb.result);
            $display("Result calculation is %d", (cb.a + cb.b));

            //Check if the result is right
            if (cb.result == (cb.a + cb.b)) begin
                $display("The result of the addition is CORRECT");
            end
            else begin
                $display("The result of the addition is FALSE");
                errors = errors + 1;
            end

            //Put valid and ready to low for the next calculation
            cb.input_valid <= 0;
            cb.output_ready <= 0;

        end;
    endtask



    // Programme lancé au démarrage de la simulation
    program TestSuite;
        initial begin
            if (testcase == 0)
                test_case0();
            if (testcase == 1)
                test_case1();
            else
                $display("Ach, test case not yet implemented");
            $display("done!");
            $display("The number of error is : %d", errors);
            $stop;
        end
    endprogram

endmodule
