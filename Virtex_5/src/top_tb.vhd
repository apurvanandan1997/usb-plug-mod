--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:52:26 06/24/2019
-- Design Name:   
-- Module Name:   /home/apurvan/tmp/temppp/test/top_tb.vhd
-- Project Name:  test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-- uncomment the following library declaration if using
-- arithmetic functions with signed or unsigned values
--use ieee.numeric_std.all;

entity top_tb is
end top_tb;

architecture behavior of top_tb is

    -- component declaration for the unit under test (uut)

    component top
    port(
        USER_CLK      : in  std_logic;
        RESET         : in  std_logic;
        DATA_LANE_0_P : out std_logic;
        DATA_LANE_0_N : out std_logic;
        CLK_LANE_P    : out std_logic;
        CLK_LANE_N    : out std_logic
        --debug         : out std_logic_vector(31 downto 0)
    );
    end component;

    --Inputs
    signal USER_CLK : std_logic := '0';
    signal RESET    : std_logic := '1';

    --Outputs
    signal DATA_LANE_0_P : std_logic;
    signal DATA_LANE_0_N : std_logic;
    signal CLK_LANE_P    : std_logic;
    signal CLK_LANE_N    : std_logic;

    -- Clock period definitions
    constant USER_CLK_period : time := 10 ns;

    --signal debug : std_logic_vector(31 downto 0);

begin

    -- Instantiate the Unit Under Test (UUT)
    uut : top port map (
        USER_CLK      => USER_CLK,
        RESET         => RESET,
        DATA_LANE_0_P => DATA_LANE_0_P,
        DATA_LANE_0_N => DATA_LANE_0_N,
        CLK_LANE_P    => CLK_LANE_P,
        CLK_LANE_N    => CLK_LANE_N
        --debug => debug
    );

    -- Clock process definitions
    USER_CLK_process : process
    begin
        USER_CLK <= '0';
        wait for USER_CLK_period/2;
        USER_CLK <= '1';
        wait for USER_CLK_period/2;
    
    end process;


    -- Stimulus process
    stim_proc : process
    begin
        -- hold reset state for 100 ns.
        wait for 100 ns;
        RESET <= '0';
        wait;
    
    end process;

end;
