

library project_lib;
context project_lib.project_ctx;

entity tester2 is

end tester2;

architecture fake of tester2 is

begin

    process is
    begin
        for i in 0 to 5 loop
            wait for 10 ns;
            logger.log_note("ceci est un test numéro 2");
        end loop;

        wait;
    end process;

end fake;
