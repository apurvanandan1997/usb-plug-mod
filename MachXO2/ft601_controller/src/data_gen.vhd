----------------------------------------------------------------------------------
-- Company:        apertus° Association
-- Engineer:       Apurva Nandan
-- 
-- Create Date:    00:22:57 08/05/2019 
-- Design Name:    USB 3.0 Plugin Module FT601 Controller
-- Module Name:    data_gen 
-- Project Name: 
-- Target Devices: MachXO2-LCMXO2-2000HC-6TG100C
-- Tool versions:  Lattice Diamond 3
-- Description:    Data generation for feeding to the FT601 controller.
--                 Currently uses just a simple 32-bit counter.
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
-- This program is free software: you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation, either version
-- 3 of the License, or (at your option) any later version.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity data_gen is
    port(
        rst : in std_logic;
        clk : in std_logic;
        -- data_req enables data output
        data_req : in  std_logic; 
        data_out : out std_logic_vector(31 downto 0)
    );

end entity data_gen;

architecture rtl of data_gen is

    signal data_buf : std_logic_vector(31 downto 0) := (others => '0');
    -- Stores the 32-bit count data
begin

    ----------------------------------------------------------------------------
    -- count_proc: 32-bit counter process for data generation
    ----------------------------------------------------------------------------
    count_proc : process(clk)
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
