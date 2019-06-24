----------------------------------------------------------------------------------
-- Company:        apertus° Association
-- Engineer:       Apurva Nandan
-- 
-- Create Date:    00:22:57 08/05/2019 
-- Design Name:    USB 3.0 Plugin Module FT601 Controller
-- Module Name:    ft601_top
-- Project Name: 
-- Target Devices: MachXO2-LCMXO2-2000HC-6TG100C
-- Tool versions:  Lattice Diamond 3
-- Description:    FT601 Controller in FT245 mode with pseudo-data
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

entity ft601_top is
    port (
        -- FT601 Activity Indicating LED
        LED : out std_logic;
        -- To/from the FT601 pads
        FT601_CLK    : in  std_logic;
        FT601_RST_N  : out std_logic;
        FT601_DATA   : out std_logic_vector(31 downto 0);
        FT601_BE     : out std_logic_vector(3 downto 0);
        FT601_RXF_N  : in  std_logic;
        FT601_TXE_N  : in  std_logic;
        FT601_WR_N   : out std_logic;
        FT601_SIWU_N : out std_logic;
        FT601_RD_N   : out std_logic;
        FT601_OE_N   : out std_logic

    );

end entity ft601_top;

architecture rtl of ft601_top is
    
    -- Component inclusions begin
    component data_gen is
        port (
            rst      : in  std_logic;
            clk      : in  std_logic;
            data_req : in  std_logic;
            data_out : out std_logic_vector(31 downto 0)
        );
    end component data_gen;

    component ft601 is
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            led : out std_logic;

            -- To FT601 chip
            ft601_data   : out std_logic_vector(31 downto 0);
            ft601_be     : out std_logic_vector(3 downto 0);
            ft601_rxf_n  : in  std_logic;
            ft601_txe_n  : in  std_logic;
            ft601_wr_n   : out std_logic;
            ft601_siwu_n : out std_logic;
            ft601_rd_n   : out std_logic;
            ft601_oe_n   : out std_logic;

            -- From Internal FIFOs
            data_in     : in  std_logic_vector(31 downto 0);
            req_data    : out std_logic;
            fifo_in_emp : in  std_logic;
            data_wr_en  : in  std_logic
        );
    end component ft601;
    -- End component inclusions

    -- Linking signals
    signal rst      : std_logic;
    signal req_data : std_logic;
    signal gen_data : std_logic_vector(31 downto 0);

begin

    FT601_RST_N <= '1';
    rst <= '0';

    ------------------------------------------------------------------------
    -- data_gen_comp: Data Generating module for feeding to the FTDI
    --                For testing purposes only. Currnetly just incoporates
    --                a 32-bit counter.
    ------------------------------------------------------------------------
    data_gen_comp : data_gen port map(
        rst      => rst,
        clk      => FT601_CLK,
        data_req => req_data,
        data_out => gen_data
    );

    ------------------------------------------------------------------------
    -- ft601_comp: The FT601Q FTDI controller in FT245 mode
    -- Version:    3.2
    ------------------------------------------------------------------------
    ft601_comp : ft601 port map(
        clk          => FT601_CLK,
        rst          => rst,
        led          => LED,
        ft601_data   => FT601_DATA,
        ft601_be     => FT601_BE,
        ft601_rxf_n  => FT601_RXF_N,
        ft601_txe_n  => FT601_TXE_N,
        ft601_wr_n   => FT601_WR_N,
        ft601_siwu_n => FT601_SIWU_N,
        ft601_rd_n   => FT601_RD_N,
        ft601_oe_n   => FT601_OE_N,
        data_in      => gen_data,
        req_data     => req_data,
        fifo_in_emp  => '0',
        data_wr_en   => '1'
    );

end architecture rtl;