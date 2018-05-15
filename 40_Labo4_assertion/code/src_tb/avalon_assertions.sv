
/* Génération de signaux de type bus avalon
*/

module avalon_assertions#(
        int AVALONMODE  = 0,
        int TESTCASE    = 0,
        int NBDATABYTES = 2,
        int NBADDRBITS  = 8,
        int WRITEDELAY  = 2,  // Delay for fixed delay write operation
        int READDELAY   = 1,  // Delay for fixed delay read operation
        int FIXEDDELAY  = 2)  // Delay for pipeline operation
(
    input logic clk,
    input logic rst,

    input logic[NBADDRBITS-1:0] address,
    input logic[NBDATABYTES:0] byteenable,
    input logic[2^NBDATABYTES-1:0] readdata,
    input logic[2^NBDATABYTES-1:0] writedata,
    input logic read,
    input logic write,
    input logic waitrequest,
    input logic readdatavalid,
    input logic[7:0] burstcount,
    input logic beginbursttransfer
);

int counter_datavalid=0;
int counter_read=0;
int burst_count=0;

    // clocking block
    default clocking cb @(posedge clk);
    endclocking

    generate

        if (AVALONMODE == 0) begin : assert_waitrequest
            // read ne doit jamais être actif en même temps que write
            assert_waitreq1: assert property
                (disable iff (rst==1)
                !(read & write));

            // Si waitRequest passe actif les sigaux (du maitre) suivants doivent être stable:
            // - adresse
            // - byteenable
            assert_stable: assert property
                (disable iff (rst==1)
                $stable(waitrequest) and waitrequest |-> $stable(address) and $stable(byteenable));

            //Si on a waitRequest et write : wrtite doit etre actif durant la durée de waitRequest
            assert_stable_write: assert property
                (disable iff (rst==1)
                $stable(waitrequest) and waitrequest and write |-> $stable(write));
            // Si waitRequest et read :  adresse et byteenable doivent être actif un cycle de plus
            assert_read_stable: assert property
                (disable iff (rst==1)
                waitrequest and read |=> $stable(address) and  $stable(byteenable));

            //Read doit rester un cycle de plus que waitRequest
            assert_read : assert property
                (disable iff (rst==1)
                $past(waitrequest) and $past(read) |-> read);

            // Si waitRequest passe à 0 et que read =1 alors readdatavalid doit être actif durant 1cycle
            assert_readdatavalid: assert property
                (disable iff (rst==1)
                $fell(waitrequest) and read |-> readdatavalid);
        end

        if (AVALONMODE == 1) begin : assert_fixed

            // read ne doit jamais être actif en même temps que write
            assert_fixed1: assert property
                (disable iff (rst==1)
                !(read & write));

            // Si read devient actif, les signaux suivants doivent rester stable durant un nombre de cycle fixe
            // - adresse
            // - byteenable
            assert_stable_read1: assert property
                (disable iff (rst==1)
                $rose(read) |=> ($stable(address)[*READDELAY+1]) and ($stable(byteenable)[*READDELAY+1]));


            // Si write devient actif, les signaux suivants doivent rester stable durant un nombre de cycle fixe
            // - adresse
            // - byteenable
            assert_stable_write1: assert property
                (disable iff (rst==1)
                $rose(write) |=> ($stable(address)[*WRITEDELAY+1]) and ($stable(byteenable)[*WRITEDELAY+1]));

            // Le comportement est identique à waitRequest sauf que le nombre de cycle est défini
        end

        //Aidé de Quentin :)
        if (AVALONMODE == 2) begin : assert_pipeline_variable

            // Si waitRequest passe actif les sigaux (du maitre) suivants doivent être stable:
            // - adresse
            // - read
            assert_stable: assert property
                (disable iff (rst==1)
                $stable(waitrequest) and waitrequest |-> $stable(address) and $stable(read));

            //Le nombre de readdatavalid doit pas dépasser le nombre de lecture
            //le nombre de lecture est obtenu lorsque waitRequest n'est pas actif
            // Repris de l'exemple du fifi p. 40 du cours assertion
            always @(posedge clk or posedge rst)
                if (rst)
                    counter_read= 0;
                else if (!waitrequest && read)
                    counter_read = counter_read + 1;

            always @(posedge clk or posedge rst)
                if (rst)
                    counter_datavalid = 0;
                else if (readdatavalid)
                    counter_datavalid = counter_datavalid + 1;

            assert_counter: assert property
                (disable iff (rst==1)
                readdatavalid |=> counter_read >= counter_datavalid);

            // Si read est actif et waitRequest inactif
            // readdatavalid doit être actif une fois dans le plus tard
            assert_readdatavalid: assert property
                (disable iff (rst==1)
                read and !waitrequest |=> ##[0:$]readdatavalid);

        end

        if (AVALONMODE == 3) begin : assert_pipeline_fixed

          // Si waitRequest passe actif les sigaux (du maitre) suivants doivent être stable:
          // - adresse
          // - read
          assert_stable: assert property
              (disable iff (rst==1)
              $stable(waitrequest) and waitrequest |-> $stable(address) and $stable(read));

          // Si read est actif et waitRequest inactif
          // readdatavalid doit être actif une fois un nombre de cycle fixe après (FIXEDDELAY)
          assert_readdatavalid: assert property
              (disable iff (rst==1)
              read and !waitrequest |-> ##FIXEDDELAY readdatavalid);

        end

        if (AVALONMODE == 4) begin : assert_burst

            //READ
            //adresse  et read doivent être stable lorsque waitRequest
            assert_stable_waitreq: assert property
                (disable iff (rst==1)
                $stable(waitrequest) and waitrequest |-> $stable(address) and $stable(read));

            // Si waitRequest et beginbursttransfer :  adresse et read doivent être actif un cycle de plus
            assert_readaddr_stable: assert property
                (disable iff (rst==1)
                waitrequest and beginbursttransfer |=> $stable(address) and  $stable(read));

            //Check burstcount
            always @(posedge clk or posedge rst)
                if (rst)
                    counter_datavalid = 0;
                else if (beginbursttransfer)
                    burst_count = burst_count + burstcount;

            //Si il y a un beginbursttransfer il faut qu'il y ait une fois dans
            //le futur une nombre de fois "burstcount" de signal readdatavalid
            /*assert_readdatavalid: assert property
                (disable iff (rst==1)
                beginbursttransfer |=> readdatavalid [=burst_count]);*/


            //WRITE
            //TODO :)

        end

    endgenerate
endmodule
