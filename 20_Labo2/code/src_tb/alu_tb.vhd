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
use ieee.std_logic_1164.all;
use IEEE.math_real.all;
use ieee.numeric_std.all;

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
    --State of the state machine for the LCD send DATA
    --------------------------------------------------------
    subtype t_mode is std_logic_vector(2 downto 0);
    --State description
    constant c_ADD : t_mode := "000";
    constant c_SUB : t_mode := "001";
    constant c_OR : t_mode := "010";
    constant c_AND : t_mode := "011";
    constant c_A : t_mode := "100";
    constant c_B : t_mode := "101";
    constant c_SIZE : t_mode := "110";
    constant c_NULL : t_mode := "111";


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


    stimulus_proc: process is

        -------------------------------------------------
        -- Procedure to set the stimulis
        ------------------------------------------------
        procedure set_sti(
            a,b: in std_logic_vector(SIZE-1 downto 0);
            mode : in std_logic_vector(2 downto 0))
        is
        --procedure set_sti(a,b,mode: in std_logic_vector) is
        begin
            a_sti <= a;
            b_sti <= b;
            mode_sti <= mode;
        end set_sti;

    begin
        -- a_sti    <= default_value;
        -- b_sti    <= default_value;
        -- mode_sti <= default_value;

        report "Starting simulation with ERRNO = " & integer'image(ERRNO);

        set_sti((others => '0'),(others => '0'), c_ADD);
        wait for 10 ns;

        set_sti((others => '1'),(others => '0'), c_SUB);
        wait for 10 ns;

        set_sti((others => '1'),(others => '1'), C_A);
        wait for 10 ns;


        -- do something
        case TESTCASE is
            when 0      => -- default testcase
            when others => report "Unsupported testcase : "
                                  & integer'image(TESTCASE)
                                  severity error;
        end case;

        -- end of simulation
        sim_end_s <= true;

        -- stop the process
        wait;

    end process; -- stimulus_proc

end testbench;
