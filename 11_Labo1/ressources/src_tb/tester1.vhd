

library project_lib;
context project_lib.project_ctx;

entity tester1 is

end tester1;

architecture fake of tester1 is

begin

    process is
    begin
        for i in 0 to 5 loop
            wait for 10 ns;
            logger.log_error("Ceci est un test numéro 1");
        end loop;

        wait;
    end process;

end fake;
