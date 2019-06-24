----------------------------------------------------------------------------------
-- Company:        apertus° Association
-- Engineer:       Apurva Nandan
-- 
-- Create Date:    00:22:57 08/05/2019 
-- Design Name:    USB 3.0 Plugin Module FT601 Controller
-- Module Name:    ft601
-- Project Name: 
-- Target Devices: MachXO2-LCMXO2-2000HC-6TG100C
-- Tool versions:  Lattice Diamond 3
-- Description:    FT601 Controller in FT245 mode
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

entity ft601 is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        led : out std_logic;

        -- To FT601 chip
        ft601_data   : inout std_logic_vector(31 downto 0);
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
        data_wr_en  : in  std_logic;

        -- To Internal FIFOs
        data_out     : out std_logic_vector(31 downto 0);
        dat_out_rdy  : out std_logic

    );

end entity ft601;

architecture rtl of ft601 is
    -- The state for the two FSM made in this design
    constant IDLE    : std_logic_vector(2 downto 0) := "000";
    constant INTMDT1 : std_logic_vector(2 downto 0) := "001";
    constant INTMDT2 : std_logic_vector(2 downto 0) := "010";
    constant INTMDT3 : std_logic_vector(2 downto 0) := "011"; 
    constant ACTIVE_RX  : std_logic_vector(2 downto 0) := "100";
    constant ACTIVE_TX  : std_logic_vector(2 downto 0) := "101";
    -- i_* are internal/intermediate signal
    -- Signal for buffering and inverting active low IOs
    signal i_state : std_logic_vector(2 downto 0) := IDLE;
    signal ft601_txe : std_logic :='0';
    signal ft601_rd : std_logic :='0';
    signal ft601_oe : std_logic :='0';
    signal ft601_rxf : std_logic :='0';
    -- Various Enable signals
    signal i_byte_en  : std_logic := '0';
    signal i_rd_en    : std_logic := '0';
    signal i_wr_en    : std_logic := '0';
    signal i_dat_rdy  : std_logic := '0';
    -- Buffer for data input and output
    signal i_dat_i_buf : std_logic_vector(31 downto 0);
    signal i_dat_o_buf : std_logic_vector(31 downto 0);
    -- For handling the data transmission to the HOST
    signal i_tx_state  : std_logic_vector(2 downto 0) := IDLE;
    signal i_valid     : std_logic_vector(2 downto 0) := "000";
    signal i_pre_valid : std_logic_vector(2 downto 0) := "000";
    signal i_data      : std_logic_vector(95 downto 0);
    signal i_pre_data  : std_logic_vector(95 downto 0);

begin

    ----------------------------------------------------------------------------
    -- sampl_proc: Buffering the control signals and data output
    ----------------------------------------------------------------------------
    sampl_proc: process(clk)
    begin
        if rising_edge(clk) then
            i_dat_o_buf <= ft601_data(7 downto 0) & ft601_data(15 downto 8) & ft601_data(23 downto 16) & ft601_data(31 downto 24);
            ft601_rxf   <= not ft601_rxf_n;
            ft601_txe   <= not ft601_txe_n;
            ft601_oe_n  <= not ft601_oe;
            ft601_rd_n  <= not ft601_rd;

        end if;
    end process;

    ----------------------------------------------------------------------------
    -- ft245_proc: Main FT245 Control FSM Process
    ----------------------------------------------------------------------------
    ft245_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                i_byte_en   <= '1';
                ft601_oe    <= '0';
                ft601_rd    <= '0';
                dat_out_rdy <= '0';
                i_rd_en     <= '0';
                i_state     <= IDLE;

            else
                if i_state = IDLE then
                    if ft601_rxf = '1' then
                        i_state   <= INTMDT1;
                        ft601_oe  <= '1';
                        i_byte_en <= '0';

                    elsif ft601_txe = '1' and i_dat_rdy = '1' then
                        i_state   <= ACTIVE_TX;
                        i_rd_en   <= '1';
                        ft601_oe  <= '0';
                        i_byte_en <= '1';

                    end if;
                elsif i_state = ACTIVE_TX then
                    if i_dat_rdy = '0' then
                        i_state <= IDLE;
                        i_rd_en <= '0';

                    end if;
                elsif i_state = INTMDT1 then
                    ft601_rd <= '1';
                    i_state  <= INTMDT2;

                elsif i_state = INTMDT2 then
                    i_state <= INTMDT3;
                elsif i_state = INTMDT3 then
                    i_state <= ACTIVE_RX;
                elsif i_state = ACTIVE_RX then
                    if ft601_rxf = '1' then
                        dat_out_rdy <= '1';
                        data_out    <= i_dat_o_buf;
                    else
                        i_byte_en   <= '1';
                        dat_out_rdy <= '0';
                        ft601_oe <= '0';
                        ft601_rd <= '0';
                        i_rd_en  <= '0';
                        i_state  <= IDLE;

                    end if;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- trans_proc: Transmission and Re-transmission of data to FT601 
    ----------------------------------------------------------------------------
    trans_proc: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                i_tx_state  <= IDLE;
                i_dat_rdy   <= '0';
                i_wr_en     <= '0';
                i_valid     <= "000";
                i_pre_valid <= "000";

            else
                if i_tx_state = IDLE then
                    if i_rd_en = '1' and ft601_txe = '1'
                        and (i_pre_valid(0) = '1' or fifo_in_emp = '0') then
                        i_tx_state  <= ACTIVE_TX;
                        i_dat_i_buf <= i_pre_data(31 downto 0);
                        i_valid(2)  <= i_pre_valid(0);
                        i_wr_en     <= i_pre_valid(0);
                        i_pre_valid <= "0" & i_pre_valid(2 downto 1);
                        i_data(95 downto 64)    <= i_pre_data(31 downto 0);
                        i_pre_data(63 downto 0) <= i_pre_data(95 downto 32);

                    end if;
                    i_dat_rdy <= i_pre_valid(0) or not fifo_in_emp;

                elsif i_tx_state = ACTIVE_TX then
                    if i_rd_en = '0' or ft601_txe = '0'
                        or (i_pre_valid(1) = '0' and fifo_in_emp ='1') then
                        i_tx_state <= INTMDT1;
                        i_dat_rdy  <= '0';

                    end if;

                    if i_pre_valid(0) = '1' then
                        i_data(95 downto 0) <= i_pre_data(31 downto 0) & i_data(95 downto 32);
                        i_dat_i_buf <= i_pre_data(31 downto 0);
                        i_pre_data(63 downto 0) <= i_pre_data(95 downto 32);

                    else
                        i_data(95 downto 0) <= data_in & i_data(95 downto 32);
                        i_dat_i_buf <= data_in;
                        i_pre_data(63 downto 0) <= i_pre_data(95 downto 32);

                    end if;
                    i_valid(2)  <= i_pre_valid(0) or data_wr_en;
                    i_valid(1)  <= i_valid(2);
                    i_valid(0)  <= i_valid(1) and not ft601_txe;
                    i_wr_en     <= i_pre_valid(0) or data_wr_en;
                    i_pre_valid <= "0" & i_pre_valid(2 downto 1);

                elsif i_tx_state = INTMDT1 then
                    i_tx_state <= INTMDT2;
                    i_wr_en    <= '0';
                    i_valid(1) <= i_valid(1) and not ft601_txe;

                elsif i_tx_state = INTMDT2 then
                    i_tx_state <= INTMDT3;
                    i_valid(2) <= i_valid(2) and not ft601_txe;

                elsif i_tx_state = INTMDT3 then
                    i_valid              <= i_valid(1 downto 0) & "0";
                    i_data(95 downto 32) <= i_data( 63 downto 0);

                    if i_valid(1 downto 0) = "00" then
                        i_tx_state <= IDLE;

                    end if;
                    if i_valid(2) = '1' then
                        i_pre_valid <= i_pre_valid(1 downto 0) & i_valid(2);
                        i_pre_data  <= i_pre_data(63 downto 0) & i_data(95 downto 64);

                    end if;
                end if;
            end if;
        end if;
    end process;

    ft601_data <= i_dat_i_buf(7 downto 0) & i_dat_i_buf(15 downto 8) & i_dat_i_buf(23 downto 16) & i_dat_i_buf(31 downto 24) when i_byte_en = '1' else (others => 'Z');
    
    req_data <= (not fifo_in_emp) and i_rd_en and ft601_txe and (not i_pre_valid(1)) when (i_tx_state = IDLE or i_tx_state = ACTIVE_TX) else '0';
    ft601_be <= "1111" when i_byte_en = '1' else (others => 'Z');
    
    ft601_siwu_n <= '1'; 
    ft601_wr_n   <= not i_wr_en;
    
    led <= not rst when i_state /= IDLE else '0';

end architecture rtl;