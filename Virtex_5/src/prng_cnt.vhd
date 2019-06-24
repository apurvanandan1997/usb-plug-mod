----------------------------------------------------------------------------
--  prng_cnt.vhd
--  Pseudo Random Generator cum 8-bit Counter
--  Version 1.0
--
--  Copyright (C) 2014 H.Poetzl
--
--  Modified by Apurva Nandan
--
--  This program is free software: you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation, either version
--  2 of the License, or (at your option) any later version.
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity prng_cnt is
    generic(
        SEED : std_logic_vector(31 downto 0) := "10101010110011001111000001010011"
    -- K28.5 Control Symbol for Word Alignment ( MSB 8 bits)
    );
    port(
        clk   : in  std_logic;  -- Clock Input
        enb   : in  std_logic;  -- Enable data generation
        mode  : in  std_logic;  -- Mode select: '1' for PRNG, '0' for 8-bit counter
        reset : in  std_logic;  -- Reset signal (To be Asserted for changing mode)
        rng   : out std_logic_vector (31 downto 0) -- Output Generated Data
    );
    
end prng_cnt;

architecture rtl of prng_cnt is

    signal fb : std_logic := '0';
    signal sr : std_logic_vector (31 downto 0) := SEED;

begin

    ----------------------------------------------------------------------------
    --  rng_cnt_proc: LFSR Random Number Generator(Fibonacci) 
    --  With availabilty of 8-bit counter mode (32,22,2,1,0)
    ----------------------------------------------------------------------------
    rng_cnt_proc : process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                if mode = '1' then
                    sr <= SEED;

                else
                    sr <= (others => '0');

                end if;
            else
                if enb = '1' then
                    if mode = '1' then
                        sr <= sr(30 downto 0) & fb;

                    else
                        sr(31 downto 24) <= sr(31 downto 24) + '1';

                    end if;
                end if;
            end if;
        end if;
    end process;

    fb  <= sr(31) xor sr(21) xor sr(1) xor sr(0);
    rng <= sr;

end rtl;
