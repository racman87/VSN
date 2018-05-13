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
2.0    02.05.2017   MRA    Modify with EX1
3.0    02.05.2017   MRA    Modify with EX2
3.0    09.05.2017   MRA    Modify with EX3

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



    //**************************************************************
    // Coverage (je ne vois pas trop comment faire des boites pour
    // les sorties, ca dépend des boites faite pour les entrées?!?!)
    //**************************************************************
    /*covergroup cov_group_out;
        cov_res: coverpoint cb.result;
    endgroup*/

    covergroup cov_group_out;
        option.at_least = 200;
        cov_res: coverpoint cb.result{
            bins tout= {[0:(2**(`DATASIZE-1))]}; //un peu bête comme test...
        }
    endgroup

    cov_group_out cg_inst = new;


    //**********
    //variables
    //**********
    //Number of errors detected
    int errors = 0;

    //Number of test to obtain 100% coverture
    integer cov_num = 0;

    //**************************************************************
    // Class to generate random constraint input value
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
        constraint order {solve a before b;
                          solve b before c;}


        //IL n'est pas possible de faire un "if" dans une calsse?
        //if (`DATASIZE > 8) begin

            // Generating coverture box
            // 0-3, 4-7, 8-11, 12-15
            covergroup cov_group;
                cov_dataa: coverpoint a {
                    //ignore_bins petit = {[0:(2**(`DATASIZE-4))]};
                    //bins min = {0};
                    bins petits = {[0:10]};
                    ignore_bins moyens = {[10:(2**(`DATASIZE-5))]};
                    bins grands = {[(2**(`DATASIZE-4)):(2**(`DATASIZE-1))]};
                    //bins max = {(2**(`DATASIZE-1))};
                }
                cov_datab: coverpoint b {
                    //bins min = {0};
                    bins petits = {[0:(2**3)]};
                    ignore_bins moyens = {[(2**3):(2**(`DATASIZE-5))]};
                    bins grands = {[(2**(`DATASIZE-4)):(2**(`DATASIZE-1))]};
                    //bins max = {(2**(`DATASIZE-1))};
                }
                cov_datac: coverpoint c {
                    //permet de séparer l'intervalle en 10 paquets égaux
                    bins tenpaquet[10] = {[0:(2**(`DATASIZE-1))]};
                }

                //Pas tout compris... une condition n'est jamais validée....
                //cov_cross : cross cov_dataa,cov_datab;

            endgroup

            function new;
              cov_group = new;
            endfunction : new

        /*end
        else begin

            //Creat a coverture group for all the input signal
            covergroup cov_group;
            	cov_dataa: coverpoint a;
            	cov_datab: coverpoint b;
              cov_datac: coverpoint c;
            endgroup

            function new;
              cov_group = new;
            endfunction : new
        end*/

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

    //Instance of random class for value a,b and c
    random_input data;

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

        //Generation of random data for a,b and c
        //random_input data;
        //Create new instance of data
        data = new();

        //Test 10 results
        //repeat(10) begin

        //while ($get_coverage() < 100) begin //Every coverture
        while (data.cov_group.get_coverage() < 100) begin //Input coverture
        //while (cg_inst.get_inst_coverage() < 100) begin //Output coverture

            $display("Total coverage is %d",$get_coverage()) ;
            $display("Input coverage is %d",data.cov_group.get_coverage()) ;
            $display("Output coverage is %d",cg_inst.get_inst_coverage()) ;

            //Generation of random data for a,b and c
            //random_input data;
            //Create new instance of data
            //data = new();
            //Randomize all the variable "rand" in data
            assert(data.randomize()) else $error("No solution for data.randomize");
            data.cov_group.sample();

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

            //Sample result to check the coverage
            cg_inst.sample();

            //Check if the result is right
            if (cb.result == (cb.a + cb.b)) begin
                $display("The result of the addition is CORRECT");
            end
            else begin
                $display("The result of the addition is FALSE");
                errors = errors + 1;
            end

            /*if (cb.b == (2**(`DATASIZE-1))) begin
                errors = errors +1;
            end*/

            //Number of test
            cov_num++;

            //Put valid and ready to low for the next calculation
            cb.input_valid <= 0;
            cb.output_ready <= 0;

        end;
    endtask


    task wait_for_coverage();
        do
            @(posedge clk);
        while (cg_inst.get_inst_coverage() < 100);
    endtask



    // Programme lancé au démarrage de la simulation
    program TestSuite;
        initial begin
            fork
              if (testcase == 0)
                  test_case0();
              else if (testcase == 1)
                  test_case1();
              else
                  $display("Ach, test case not yet implemented");
              wait_for_coverage();
            join
            disable fork;
            $display("done!");
            $display("The number of error is : %d", errors);
            $display("The number of test is : %d", cov_num);
            $stop;
        end
    endprogram

endmodule
