----------------------------------------------------------------------------------
-- Company:        apertus° Association
-- Engineer:       Apurva Nandan
-- 
-- Create Date:    00:22:57 08/05/2019 
-- Design Name: 
-- Module Name:    data_gen 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity data_gen is
    port (
        rst   : in  std_logic;
        clk     : in  std_logic;
        data_req : in  std_logic;
        data_out : out std_logic_vector (31 downto 0)
        );

end entity data_gen;


architecture rtl of data_gen is

    signal data_buf : std_logic_vector (31 downto 0) := (others=> '0');
 
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                data_buf <= (others => '0');
            
            elsif data_req = '1' then
                data_buf <= data_buf + '1'; 

            end if;
        end if;
    end process;

    data_out <= data_buf;

end rtl;    
