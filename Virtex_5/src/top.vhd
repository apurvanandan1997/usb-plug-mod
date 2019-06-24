----------------------------------------------------------------------------------
-- Company:        apertus° Association
-- Engineer:       Apurva Nandan
-- 
-- Create Date:    17:33 June 23,2019 
-- Design Name:    USB 3.0 Plugin BER Calculation 
-- Module Name:    top
-- Project Name:   
-- Target Device:  XC5VLX110T-FF1136-1
-- Tool Version:   Xilinx ISE 14.7
-- Description:    This design is used for calculating the BER of the 6 LVDS
--                 connection from the main board of AXIOM Beta to the USB 3.0
--                 plugin module. This design is meant to run on Virtex-5 FPGA.
----------------------------------------------------------------------------------
-- This program is free software: you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation, either version
-- 3 of the License, or (at your option) any later version.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

Library unisim;
use unisim.vcomponents.all;

entity top is
    port (
        USER_CLK : in std_logic;
        RESET    : in std_logic;
        -- Data and Clock LVDS lanes
        DATA_LANE_0_P : out std_logic;
        DATA_LANE_0_N : out std_logic;
        CLK_LANE_P    : out std_logic;
        CLK_LANE_N    : out std_logic
    --debug : out std_logic_vector(31 downto 0)
    );

end top;

architecture rtl of top is

    signal rng        : std_logic_vector (31 downto 0);
    signal enc10b_dat : std_logic_vector(9 downto 0);

    signal rst       : std_logic;
    signal locked    : std_logic;
    signal clkfbout  : std_logic;
    signal clk       : std_logic;
    signal sclk      : std_logic;
    signal clk_bufg  : std_logic;
    signal sclk_bufg : std_logic;

    signal ser_data   : std_logic := '0';
    signal shift1_dat : std_logic := '0';
    signal shift2_dat : std_logic := '0';

    signal ser_clk    : std_logic := '0';
    signal shift1_clk : std_logic := '0';
    signal shift2_clk : std_logic := '0';


begin

    rst <= RESET or not locked;

    ----------------------------------------------------------------------------
    -- PLL_BASE: Phase-Lock Loop Clock Circuit
    -- Virtex-5
    -- Xilinx HDL Libraries Guide, version 11.2 
    ----------------------------------------------------------------------------
    PLL_BASE_inst : PLL_BASE
        generic map (
            BANDWIDTH          => "OPTIMIZED",          -- "HIGH", "LOW" or "OPTIMIZED"
            CLKFBOUT_MULT      => 5,                    -- Multiplication factor for all output clocks
            CLKFBOUT_PHASE     => 0.0,                  -- Phase shift (degrees) of all output clocks
            CLKIN_PERIOD       => 10.000,               -- Clock period (ns) of input clock on CLKIN
            CLKOUT0_DIVIDE     => 5,                    -- Division factor for CLKOUT0 (1 to 128)
            CLKOUT0_DUTY_CYCLE => 0.5,                  -- Duty cycle for CLKOUT0 (0.01 to 0.99)
            CLKOUT0_PHASE      => 0.0,                  -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
            CLKOUT1_DIVIDE     => 1,                    -- Division factor for CLKOUT1 (1 to 128)
            CLKOUT1_DUTY_CYCLE => 0.5,                  -- Duty cycle for CLKOUT1 (0.01 to 0.99)
            CLKOUT1_PHASE      => 0.0,                  -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
            COMPENSATION       => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRNOUS", "SOURCE_SYNCHRNOUS", 
                                                        -- "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
            DIVCLK_DIVIDE => 1,                         -- Division factor for all clocks (1 to 52)
            REF_JITTER    => 0.100                      -- Input reference jitter (0.000 to 0.999 UI%)


        )
        port map (
            CLKFBOUT => clkfbout, -- General output feedback signal
            CLKOUT0  => clk_bufg, -- One of six general clock output signals
            CLKOUT1  => sclk_bufg,-- One of six general clock output signals
            LOCKED   => locked,   -- Active high PLL lock signal
            CLKFBIN  => clkfbout, -- Clock feedback input
            CLKIN    => USER_CLK, -- Clock input
            RST      => RESET     -- Asynchronous PLL reset
        );
    -- End of PLL_BASE_inst instantiation

    ----------------------------------------------------------------------------
    -- OSERDES: Output SERDES
    -- Virtex-5
    -- Xilinx HDL Libraries Guide, version 11.2
    ----------------------------------------------------------------------------
    master_serdes_inst_data : OSERDES
        generic map (
            DATA_RATE_OQ => "DDR",      -- Specify data rate to "DDR" or "SDR"
            DATA_RATE_TQ => "DDR",      -- Specify data rate to "DDR", "SDR", or "BUF"
            DATA_WIDTH   => 10,         -- Specify data width - For DDR: 4,6,8, or 10
                                        -- For SDR or BUF: 2,3,4,5,6,7, or 8
            INIT_OQ        => '0',      -- INIT for Q1 register - ’1’ or ’0’
            INIT_TQ        => '0',      -- INIT for Q2 register - ’1’ or ’0’
            SERDES_MODE    => "MASTER", -- Set SERDES mode to "MASTER" or "SLAVE"
            SRVAL_OQ       => '0',      -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            SRVAL_TQ       => '0',      -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            TRISTATE_WIDTH => 1         -- Specify parallel to serial converter width
            )                           -- When DATA_RATE_TQ = DDR: 2 or 4
                                        -- When DATA_RATE_TQ = SDR or BUF: 1 "

        port map (
            OQ        => ser_data,      -- 1-bit output
            SHIFTOUT1 => open,          -- 1-bit data expansion output
            SHIFTOUT2 => open,          -- 1-bit data expansion output
            TQ        => open,          -- 1-bit 3-state control output
            CLK       => sclk,          -- 1-bit clock input
            CLKDIV    => clk,           -- 1-bit divided clock input
            D1        => enc10b_dat(0), -- 1-bit parallel data input
            D2        => enc10b_dat(1), -- 1-bit parallel data input
            D3        => enc10b_dat(2), -- 1-bit parallel data input
            D4        => enc10b_dat(3), -- 1-bit parallel data input
            D5        => enc10b_dat(4), -- 1-bit parallel data input
            D6        => enc10b_dat(5), -- 1-bit parallel data input
            OCE       => '1',           -- 1-bit clock enable input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => shift1_dat,        -- 1-bit data expansion input
            SHIFTIN2  => shift2_dat,        -- 1-bit data expansion input
            SR        => rst,           -- 1-bit set/reset input
            T1        => '0',           -- 1-bit parallel 3-state input
            T2        => '0',           -- 1-bit parallel 3-state input
            T3        => '0',           -- 1-bit parallel 3-state input
            T4        => '0',           -- 1-bit parallel 3-state input
            TCE       => '0'            -- 1-bit 3-state signal clock enable input
        );

    slave_serdes_inst_data : OSERDES
        generic map (
            DATA_RATE_OQ => "DDR",     -- Specify data rate to "DDR" or "SDR"
            DATA_RATE_TQ => "DDR",     -- Specify data rate to "DDR", "SDR", or "BUF"
            DATA_WIDTH   => 10,        -- Specify data width - For DDR: 4,6,8, or 10
                                       -- For SDR or BUF: 2,3,4,5,6,7, or 8
            INIT_OQ        => '1',     -- INIT for Q1 register - ’1’ or ’0’
            INIT_TQ        => '1',     -- INIT for Q2 register - ’1’ or ’0’
            SERDES_MODE    => "SLAVE", -- Set SERDES mode to "MASTER" or "SLAVE"
            SRVAL_OQ       => '0',     -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            SRVAL_TQ       => '0',     -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            TRISTATE_WIDTH => 1        -- Specify parallel to serial converter width
        )                              -- When DATA_RATE_TQ = DDR: 2 or 4
                                       -- When DATA_RATE_TQ = SDR or BUF: 1 "

        port map (
            OQ        => open,          -- 1-bit output
            SHIFTOUT1 => shift1_dat,        -- 1-bit data expansion output
            SHIFTOUT2 => shift2_dat,        -- 1-bit data expansion output
            TQ        => open,          -- 1-bit 3-state control output
            CLK       => sclk,          -- 1-bit clock input
            CLKDIV    => clk,           -- 1-bit divided clock input
            D1        => '0',           -- 1-bit parallel data input
            D2        => '0',           -- 1-bit parallel data input
            D3        => enc10b_dat(6), -- 1-bit parallel data input
            D4        => enc10b_dat(7), -- 1-bit parallel data input
            D5        => enc10b_dat(8), -- 1-bit parallel data input
            D6        => enc10b_dat(9), -- 1-bit parallel data input
            OCE       => '1',           -- 1-bit clock enable input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit data expansion input
            SHIFTIN2  => '0',           -- 1-bit data expansion input
            SR        => rst,           -- 1-bit set/reset input
            T1        => '0',           -- 1-bit parallel 3-state input
            T2        => '0',           -- 1-bit parallel 3-state input
            T3        => '0',           -- 1-bit parallel 3-state input
            T4        => '0',           -- 1-bit parallel 3-state input
            TCE       => '0'            -- 1-bit 3-state signal clock enable input
        );

    master_serdes_inst_clk : OSERDES
        generic map (
            DATA_RATE_OQ => "DDR",      -- Specify data rate to "DDR" or "SDR"
            DATA_RATE_TQ => "DDR",      -- Specify data rate to "DDR", "SDR", or "BUF"
            DATA_WIDTH   => 10,         -- Specify data width - For DDR: 4,6,8, or 10
                                        -- For SDR or BUF: 2,3,4,5,6,7, or 8
            INIT_OQ        => '0',      -- INIT for Q1 register - ’1’ or ’0’
            INIT_TQ        => '0',      -- INIT for Q2 register - ’1’ or ’0’
            SERDES_MODE    => "MASTER", -- Set SERDES mode to "MASTER" or "SLAVE"
            SRVAL_OQ       => '0',      -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            SRVAL_TQ       => '0',      -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            TRISTATE_WIDTH => 1         -- Specify parallel to serial converter width
            )                           -- When DATA_RATE_TQ = DDR: 2 or 4
                                        -- When DATA_RATE_TQ = SDR or BUF: 1 "

        port map (
            OQ        => ser_clk,      -- 1-bit output
            SHIFTOUT1 => open,          -- 1-bit data expansion output
            SHIFTOUT2 => open,          -- 1-bit data expansion output
            TQ        => open,          -- 1-bit 3-state control output
            CLK       => sclk,          -- 1-bit clock input
            CLKDIV    => clk,           -- 1-bit divided clock input
            D1        => '1', -- 1-bit parallel data input
            D2        => '0', -- 1-bit parallel data input
            D3        => '1', -- 1-bit parallel data input
            D4        => '0', -- 1-bit parallel data input
            D5        => '1', -- 1-bit parallel data input
            D6        => '0', -- 1-bit parallel data input
            OCE       => '1',           -- 1-bit clock enable input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => shift1_clk,        -- 1-bit data expansion input
            SHIFTIN2  => shift2_clk,        -- 1-bit data expansion input
            SR        => rst,           -- 1-bit set/reset input
            T1        => '0',           -- 1-bit parallel 3-state input
            T2        => '0',           -- 1-bit parallel 3-state input
            T3        => '0',           -- 1-bit parallel 3-state input
            T4        => '0',           -- 1-bit parallel 3-state input
            TCE       => '0'            -- 1-bit 3-state signal clock enable input
        );

    slave_serdes_inst_clk : OSERDES
        generic map (
            DATA_RATE_OQ => "DDR",     -- Specify data rate to "DDR" or "SDR"
            DATA_RATE_TQ => "DDR",     -- Specify data rate to "DDR", "SDR", or "BUF"
            DATA_WIDTH   => 10,        -- Specify data width - For DDR: 4,6,8, or 10
                                       -- For SDR or BUF: 2,3,4,5,6,7, or 8
            INIT_OQ        => '1',     -- INIT for Q1 register - ’1’ or ’0’
            INIT_TQ        => '1',     -- INIT for Q2 register - ’1’ or ’0’
            SERDES_MODE    => "SLAVE", -- Set SERDES mode to "MASTER" or "SLAVE"
            SRVAL_OQ       => '0',     -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            SRVAL_TQ       => '0',     -- Define Q1 output value upon SR assertion - ’1’ or ’0’
            TRISTATE_WIDTH => 1        -- Specify parallel to serial converter width
        )                              -- When DATA_RATE_TQ = DDR: 2 or 4
                                       -- When DATA_RATE_TQ = SDR or BUF: 1 "

        port map (
            OQ        => open,          -- 1-bit output
            SHIFTOUT1 => shift1_clk,        -- 1-bit data expansion output
            SHIFTOUT2 => shift2_clk,        -- 1-bit data expansion output
            TQ        => open,          -- 1-bit 3-state control output
            CLK       => sclk,          -- 1-bit clock input
            CLKDIV    => clk,           -- 1-bit divided clock input
            D1        => '0',           -- 1-bit parallel data input
            D2        => '0',           -- 1-bit parallel data input
            D3        => '1', -- 1-bit parallel data input
            D4        => '0', -- 1-bit parallel data input
            D5        => '1', -- 1-bit parallel data input
            D6        => '0', -- 1-bit parallel data input
            OCE       => '1',           -- 1-bit clock enable input
            REV       => '0',           -- Must be tied to logic zero
            SHIFTIN1  => '0',           -- 1-bit data expansion input
            SHIFTIN2  => '0',           -- 1-bit data expansion input
            SR        => rst,           -- 1-bit set/reset input
            T1        => '0',           -- 1-bit parallel 3-state input
            T2        => '0',           -- 1-bit parallel 3-state input
            T3        => '0',           -- 1-bit parallel 3-state input
            T4        => '0',           -- 1-bit parallel 3-state input
            TCE       => '0'            -- 1-bit 3-state signal clock enable input
        );

    -- End of OSERDES_inst instantiation

    ----------------------------------------------------------------------------
    --  prng_cnt: LFSR Random Number Generator (Fibonacci (32,22,2,1,0)) 
    --  With availabilty of 8-bit counter mode
    --  Copyright (C) 2014 H.Poetzl, Version 1.0
    ----------------------------------------------------------------------------
    data_gen_inst : entity work.prng_cnt
        generic map (
            SEED => "10101010110011001111000001010011"
        )
        port map (
            clk   => clk,
            enb   => '1',
            mode  => '1',
            reset => rst,
            rng   => rng
        );

    ----------------------------------------------------------------------------
    -- enc_8b10b: 8-bit to 10-bit Encoder
    -- Author: Ken Boyette, Critia Computer, Inc.
    -- Version 1.0
    ----------------------------------------------------------------------------
    enc_inst : entity work.enc_8b10b
        port map (
            KI => '0',
            AI => rng(24),
            BI => rng(25),
            CI => rng(26),
            DI => rng(27),
            EI => rng(28),
            FI => rng(29),
            GI => rng(30),
            HI => rng(31),
            -- 8-bit input for decoding
            JO => enc10b_dat(9),
            HO => enc10b_dat(8),
            GO => enc10b_dat(7),
            FO => enc10b_dat(6),
            IO => enc10b_dat(5),
            EO => enc10b_dat(4),
            DO => enc10b_dat(3),
            CO => enc10b_dat(2),
            BO => enc10b_dat(1),
            AO => enc10b_dat(0),
            -- 10-bit decoded output
            RESET    => rst,
            SBYTECLK => clk
        );

    ----------------------------------------------------------------------------
    -- BUFG: Global Clock Buffer
    -- Virtex-5
    -- Xilinx HDL Libraries Guide, version 11.2
    ----------------------------------------------------------------------------
    BUFG_inst0 : BUFG
        port map (
            O => sclk,     -- 1-bit Clock buffer output
            I => sclk_bufg -- 1-bit Clock buffer input
        );

    BUFG_inst1 : BUFG
        port map (
            O => clk,     -- 1-bit Clock buffer output
            I => clk_bufg -- 1-bit Clock buffer input
        );
    -- End of BUFG_inst instantiation

    ----------------------------------------------------------------------------
    -- OBUFDS: Differential Output Buffer
    -- Virtex-5
    -- Xilinx HDL Libraries Guide, version 11.2
    ----------------------------------------------------------------------------
    OBUFDS_inst0 : OBUFDS
        generic map (
            IOSTANDARD => "DEFAULT",
            SLEW       => "SLOW"
        )
        port map (
            O  => DATA_LANE_0_P, -- Diff_p output
            OB => DATA_LANE_0_N, -- Diff_n output
            I  => ser_data       -- Buffer input
        );

    OBUFDS_inst1 : OBUFDS
        generic map (
            IOSTANDARD => "DEFAULT",
            SLEW       => "SLOW"
        )
        port map (
            O  => CLK_LANE_P, -- Diff_p output
            OB => CLK_LANE_N, -- Diff_n output
            I  => ser_clk        -- Buffer input
        );
    -- End of OBUFDS_inst instantiation

    --	debug(31 downto 22) <= enc10b_dat;

end rtl;
