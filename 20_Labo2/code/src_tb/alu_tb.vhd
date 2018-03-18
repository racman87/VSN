--------------------------------------------------------------------------------
-- HEIG-VD
-- Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- School of Business and Engineering in Canton de Vaud
--------------------------------------------------------------------------------
-- REDS Institute
-- Reconfigurable Embedded Digital Systems
--------------------------------------------------------------------------------
--
-- File     : alu_tb.vhd
-- Author   : TbGenerator
-- Date     : 08.03.2018
--
-- Context  :
--
--------------------------------------------------------------------------------
-- Description : This module is a simple VHDL testbench.
--               It instanciates the DUV and proposes a TESTCASE generic to
--               select which test to start.
--
--------------------------------------------------------------------------------
-- Dependencies : -
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        Person     Comments
-- 0.1   08.03.2018  TbGen      Initial version
--------------------------------------------------------------------------------

library ieee;
library common_lib;
use ieee.std_logic_1164.all;
use IEEE.math_real.all;
use ieee.numeric_std.all;
use common_lib.logger_pkg.all;


entity alu_tb is
    generic (
        TESTCASE : integer := 0;
        SIZE     : integer := 8;
        ERRNO    : integer := 0
    );

end alu_tb;

architecture testbench of alu_tb is

    signal a_sti    : std_logic_vector(SIZE-1 downto 0);
    signal b_sti    : std_logic_vector(SIZE-1 downto 0);
    signal s_obs    : std_logic_vector(SIZE-1 downto 0);
    signal c_obs    : std_logic;
    signal mode_sti : std_logic_vector(2 downto 0);

    signal sim_end_s : boolean := false;
    signal clk_sti : std_logic;
    signal i : integer :=0;
    signal ref : std_logic_vector(SIZE-1 downto 0);
    signal ref_c : std_logic;

    ---------------
    -- Constants --
    ---------------
    constant CLK_PERIOD : time := 10 ns;

    component alu is
    generic (
        SIZE  : integer := 8;
        ERRNO : integer := 0
    );
    port (
        a_i    : in std_logic_vector(SIZE-1 downto 0);
        b_i    : in std_logic_vector(SIZE-1 downto 0);
        s_o    : out std_logic_vector(SIZE-1 downto 0);
        c_o    : out std_logic;
        mode_i : in std_logic_vector(2 downto 0)
    );
    end component;

    --------------------------------------------------------
    --Wich mode for the ALU
    --------------------------------------------------------
    subtype t_mode is std_logic_vector(2 downto 0);
    --State description
    constant c_ADD : t_mode := "000";
    constant c_SUB : t_mode := "001";
    constant c_OR : t_mode := "010";
    constant c_AND : t_mode := "011";
    constant c_A : t_mode := "100";
    constant c_B : t_mode := "101";
    constant c_EQUAL : t_mode := "110";
    constant c_NULL : t_mode := "111";

    -- Simply exports a logger that can be used accross entities
    shared variable logger : common_lib.logger_pkg.logger_t;

begin

    duv : alu
    generic map (
        SIZE  => SIZE,
        ERRNO => ERRNO
    )
    port map (
        a_i    => a_sti,
        b_i    => b_sti,
        s_o    => s_obs,
        c_o    => c_obs,
        mode_i => mode_sti
    );

--------------------------------------------------------------------------------
-- Génération du signal de synchro
--------------------------------------------------------------------------------
    synchro_proc: process is
    begin
        while not sim_end_s loop
            clk_sti <= '1', '0' after CLK_PERIOD/2;
            wait for CLK_PERIOD;
        end loop;
        wait;
    end process;

--------------------------------------------------------------------------------
-- Processus to set the stimulus
--------------------------------------------------------------------------------
    stimulus_proc: process is
        variable a, b, c      : integer; --random integers
        variable seed1, seed2 : positive; --seeds
        variable rand         : real; --random output

        -------------------------------------------------
        -- Function to convert integer to std_logic_vector
        ------------------------------------------------
        function to_std_logic_vect(val : in integer) return std_logic_vector is
          variable result : std_logic_vector(SIZE-1 downto 0);
        begin
          result := std_logic_vector(to_unsigned(val,SIZE));
          return result;
        end to_std_logic_vect;

        -------------------------------------------------
        -- Procedure to set the stimulis
        ------------------------------------------------
        procedure set_sti(
            a,b: in std_logic_vector(SIZE-1 downto 0);
            mode : in std_logic_vector(2 downto 0))
        is
        begin
            a_sti <= a;
            b_sti <= b;
            mode_sti <= mode;
        end set_sti;

        -------------------------------------------------
        -- Function du calculate de result of the operation
        -- for the random tests
        ------------------------------------------------
        function create_ref(a,b,c : in integer) return std_logic_vector is
            variable sum : integer;
            variable result : std_logic_vector(SIZE-1 downto 0);
            variable a_s: std_logic_vector(SIZE downto 0);
          	variable b_s: std_logic_vector(SIZE downto 0);
          	variable s_s: std_logic_vector(SIZE downto 0);
        begin
            a_s:="0" & to_std_logic_vect(a);
            b_s:="0" & to_std_logic_vect(b);

            case c is
                when 0 =>
                    s_s:=std_logic_vector(unsigned(a_s)+unsigned(b_s));
                    result := s_s(7 downto 0);
                when 1 =>
                    s_s:=std_logic_vector(unsigned(a_s)-unsigned(b_s));
                    result := s_s(7 downto 0);
                when 2 => result := to_std_logic_vect(a) OR to_std_logic_vect(b);
                when 3 => result := to_std_logic_vect(a) AND to_std_logic_vect(b);
                when 4 => result := to_std_logic_vect(a);
                when 5 => result := to_std_logic_vect(b);
                when 6 =>
                  if a = b then
                      result:= (others => '1');
                  else
                      result:= (others => '0');
                  end if;
                when 7 => result := (others => '0');
                when others => report "Unsupported mode_sti";
            end case;
            --result := to_std_logic_vect(sum);
            return result;
        end create_ref;

        -------------------------------------------------
        -- Function du calculate the carry of the operation
        -- add and sub for the random tests
        ------------------------------------------------
        function create_carry(a,b,c : in integer) return std_logic is
            variable result : std_logic;
            variable value,a_s,b_s : std_logic_vector(SIZE downto 0);
            variable mode : std_logic_vector(2 downto 0);
        begin
            a_s:="0" & to_std_logic_vect(a);
            b_s:="0" & to_std_logic_vect(b);

            case c is
                when 0 =>
                    value :=std_logic_vector(unsigned(a_s)+unsigned(b_s));-- a + b;
                    mode := "000";
                when 1 =>
                    value := std_logic_vector(unsigned(a_s)-unsigned(b_s));--a - b;
                    mode := "001";
                when others => report "Unsupported mode_sti";
            end case;

            if ((ERRNO mod 2)=0) then
        			result:='0';
        		else
        			result:='1';
        		end if;
        		if (mode(2 downto 1)="00") then
        			result:=value(SIZE);
        			if ERRNO=16 then
        				result := not value(SIZE);
        			end if;
        		end if;

            return result;
        end create_carry;

    begin

        -------------------------------------------------
        -- Set the parameters for the log
        ------------------------------------------------
        logger.write_enable_file;
        logger.set_severity(warning);
        logger.log_warning("Starting simulation with ERRNO = " & integer'image(ERRNO));

        -------------------------------------------------
        -- Set one case for each operation
        ------------------------------------------------
        for i in 0 to 7 loop
            wait until falling_edge(clk_sti);
            wait for 2 ns;
            case i is
                when 0 => set_sti((others => '1'), to_std_logic_vect(1), c_ADD);
                when 1 => set_sti((others => '1'),(others => '1'), c_SUB);
                when 2 => set_sti((others => '1'),(others => '0'), c_OR);
                when 3 => set_sti((others => '1'),(others => '0'), c_AND);
                when 4 => set_sti(to_std_logic_vect(24),to_std_logic_vect(32), c_A);
                when 5 => set_sti(to_std_logic_vect(10),to_std_logic_vect(53), c_B);
                when 6 => set_sti(to_std_logic_vect(43),to_std_logic_vect(43), c_EQUAL);
                when 7 => set_sti((others => '1'),(others => '1'), c_NULL);
                when others => report "Unsupported mode_sti";
            end case;
        end loop;

        -------------------------------------------------
        -- Test 1000 random tests
        ------------------------------------------------
      for i in 0 to (1000-1) loop
          wait until falling_edge(clk_sti);
          wait for 2 ns;
          -- Generate random stimulus betwwen 0..65535
          UNIFORM(seed1, seed2, rand);
          a := INTEGER(TRUNC(REAL(65535)*rand));
          a_sti <= to_std_logic_vect(a);
          UNIFORM(seed1, seed2, rand);
          b := INTEGER(TRUNC(REAL(65535)*rand));
          b_sti <= to_std_logic_vect(b);
          -- Generate random stimulus betwwen 0..7
          UNIFORM(seed1, seed2, rand);
          c := INTEGER(TRUNC(REAL(7)*rand));

          case c is
              when 0 => mode_sti <= c_ADD;
              when 1 => mode_sti <= c_SUB;
              when 2 => mode_sti <=  c_OR;
              when 3 => mode_sti <= c_AND;
              when 4 => mode_sti <= c_A;
              when 5 => mode_sti <= c_B;
              when 6 => mode_sti <= c_EQUAL;
              when 7 => mode_sti <= c_NULL;
              when others => report "Unsupported mode_sti";
          end case;

          ref <= create_ref(a, b, c);
          if c=0 OR c=1 then
              ref_c <= create_carry(a,b,c);
          end if;

      end loop;

        -- do something
        case TESTCASE is
            when 0      => -- default testcase
            when others => report "Unsupported testcase : "
                                  & integer'image(TESTCASE)
                                  severity error;
        end case;

        -- stop the process
        wait;

    end process; -- stimulus_proc

--------------------------------------------------------------------------------
-- Processus to test the result of the ALU
--------------------------------------------------------------------------------
    observation_proc: process is

        -------------------------------------------------
        -- Function to convert integer to std_logic_vector
        ------------------------------------------------
        function to_std_logic_vect(val : in integer) return std_logic_vector is
          variable result : std_logic_vector(SIZE-1 downto 0);
        begin
          result := std_logic_vector(to_unsigned(val,SIZE));
          return result;
        end to_std_logic_vect;


        -------------------------------------------------
        -- Procedure to test the observation
        ------------------------------------------------
        procedure test_obs(
            s_ref : in std_logic_vector(SIZE-1 downto 0);
            c_ref : in std_logic)
        is
        begin
            logger.log_note("The test was done with mode = " & integer'image(to_integer(unsigned(mode_sti))));

            -------------------------------------------------
            -- Testing of the results
            ------------------------------------------------
            if mode_sti = c_EQUAL then
                if s_obs(0)=s_ref(0) then
                    logger.log_note("Result output was right for comparison");
                else
                    logger.log_error("Result output was false for comparison");
                end if;
            elsif s_obs /= s_ref then
                case mode_sti is
                    when c_ADD => logger.log_error("Result output was false for addition");
                    when c_SUB => logger.log_error("Result output was false for substraction");
                    when c_OR => logger.log_error("Result output was false for OR operation");
                    when c_AND => logger.log_error("Result output was false for AND operation");
                    when c_A => logger.log_error("Result output was false for A");
                    when c_B => logger.log_error("Result output was false for B");
                    --when c_EQUAL => logger.log_error("Result for comparison is false");
                    when c_NULL => logger.log_error("Result is not 0");
                    when others => report "Unsupported mode_sti";
                end case;
            else
                --report "output was successfully verified";
                case mode_sti is
                    when "000" =>
                        logger.log_note("Result output was right for addition");
                        -------------------------------------------------
                        -- Testing of the carry
                        ------------------------------------------------
                        if c_obs /= c_ref then
                            logger.log_error("Carry output was false for addition");
                        else
                            logger.log_note("Carry output was successfully verified");
                        end if;
                    when "001" =>
                        logger.log_note("Result output was right for substraction");
                        -------------------------------------------------
                        -- Testing of the carry
                        ------------------------------------------------
                        if c_obs /= c_ref then
                            logger.log_error("Carry output was false for substraction");
                        else
                            logger.log_note("Carry output was successfully verified");
                        end if;
                    when c_OR => logger.log_note("Result output was right for OR operation");
                    when c_AND => logger.log_note("Result output was right for AND operation");
                    when c_A => logger.log_note("Result output was right for A");
                    when c_B => logger.log_note("Result output was right for B");
                    --when c_EQUAL => logger.log_note("Result for comparison is right");
                    when c_NULL => logger.log_note("Result is 0");
                    when others => report "Unsupported mode_sti";
                end case;
            end if;
        end test_obs;

    begin

        -------------------------------------------------
        -- Test one case for each operation
        ------------------------------------------------
        for i in 0 to 7 loop
            wait until rising_edge(clk_sti);
            wait for 2 ns;
            case i is
                -- Addition
                when 0 => test_obs(to_std_logic_vect(0),'1');
                -- Substraction
                when 1 => test_obs((others => '0'),'0');
                -- OR
                when 2 => test_obs((others => '1'),'0');
                -- AND
                when 3 => test_obs((others => '0'),'0');
                -- A
                when 4 => test_obs(to_std_logic_vect(24),'0');
                -- B
                when 5 => test_obs(to_std_logic_vect(53),'0');
                -- A = B
                when 6 => test_obs(to_std_logic_vect(1),'0');
                -- 0
                when 7 => test_obs((others => '0'),'0');
                when others => report "Unsupported mode";
            end case;
        end loop;


        -------------------------------------------------
        -- 1000 random tests
        ------------------------------------------------
        for i in 0 to (1000-1) loop -- mettre 100 à la place de 10
            wait until rising_edge(clk_sti);
            wait for 2 ns;
            logger.log_note("The random mode is = " & integer'image(to_integer(unsigned(mode_sti))));
            case mode_sti is
              -- Addition
              when c_ADD => test_obs(ref,ref_c);
              -- Substraction
              when c_SUB => test_obs(ref,ref_c);
              -- OR
              when c_OR => test_obs(ref,'0');
              -- AND
              when c_AND => test_obs(ref,'0');
              -- A
              when c_A => test_obs(ref,'0');
              -- B
              when c_B => test_obs(ref,'0');
              -- A = B
              when c_EQUAL => test_obs(ref,'0');
              -- 0
              when c_NULL => test_obs(ref,'0');
              when others => report "Unsupported mode";
            end case;
        end loop;


        -------------------------------------------------
        -- Result of the overal test
        ------------------------------------------------
        logger.log_warning("The number of error is " & integer'image(logger.get_error_counter));
        if logger.get_error_counter /= 0 then
            logger.log_warning("ALU is unsuccessfully verified");
        else
            logger.log_warning("ALU is successfully verified");
        end if;


        -- end of simulation
        sim_end_s <= true;

        -- stop the process
        wait;

    end process; -- stimulus_proc

end testbench;
