library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UART is
	generic(
		CLK_INPUT 	: integer := 40000000;
		DATA_BITS	: natural := 8;	-- number of bits
		ADDR_BIT		: natural := 4	-- number of address bits
	);
	port(
		clk		: in std_logic;
		reset		: in std_logic;
		rx			: in std_logic;
		rd			: in std_logic;
		wr			: in std_logic;
		
		dnum		: in std_logic;
		snum		: in std_logic;
		par		: in std_logic_vector(1 downto 0);
		bd_rate	: in std_logic_vector(1 downto 0);
		
		w_data	: in std_logic_vector(DATA_BITS-1 downto 0);
		tx			: out std_logic;
		rx_empty	: out std_logic;
		rx_full	: out std_logic;
		tx_full	: out std_logic;
		
		err		: out std_logic_vector(2 downto 0);
		
		r_data	: out std_logic_vector(DATA_BITS-1 downto 0)
	);
end UART;

architecture behavior of UART is
	signal s_tick		 	: std_logic;
	signal rx_done_tick 	: std_logic;
	signal tx_done_tick 	: std_logic;
	signal rx_data 		: std_logic_vector(DATA_BITS-1 downto 0);
	signal tx_data			: std_logic_vector(DATA_BITS-1 downto 0);
	signal tx_empty		: std_logic;
	signal n_tx_empty		: std_logic;
	
	signal fifo_full		: std_logic;
begin
	rx_full <= fifo_full;
	n_tx_empty <= not tx_empty;
	uut_BaudRate_generator: entity work.BaudRate_generator(behavior)
		GENERIC MAP(
			CLK_INPUT 	=> CLK_INPUT
		)
		PORT MAP(
			clk		=> clk,
			bd_rate	=> bd_rate,
			tick		=> s_tick
		);
	
	uut_receiver: entity work.receiver(behavior)
		GENERIC MAP(
			DBIT		=> DATA_BITS
		)
		PORT MAP (
          clk => clk,
          reset => reset,
          rx => rx,
          s_tick => s_tick,
          rx_done_tick => rx_done_tick,
          dout => rx_data,
			 dnum => dnum,
			 snum => snum,
			 par => par,
			 err => err,
			 fifo_full =>fifo_full
      );
	uut_rx_fifo: entity work.fifo(behavior)
		GENERIC MAP(
			B => DATA_BITS,
			W => ADDR_BIT
		)
		PORT MAP (
			clk		=> clk,
			reset		=> reset,
			rd			=> rd,
			wr			=> rx_done_tick,
			w_data	=> rx_data,
			empty		=> rx_empty,
			full		=> fifo_full,
			r_data	=> r_data
		);
	uut_transmitter: entity work.transmitter(behavior)
		GENERIC MAP(
			DBIT		=> DATA_BITS
		)
		PORT MAP(
			clk				=> clk,
			reset				=> reset,
			tx_start			=> n_tx_empty,
			s_tick			=> s_tick,
			din				=> tx_data,
			tx_done_tick	=> tx_done_tick,
			tx					=> tx,
			dnum => dnum,
			snum => snum,
			par => par
		);
	uut_tx_fifo: entity work.fifo(behavior)
		GENERIC MAP(
			B => DATA_BITS,
			W => ADDR_BIT
		)
		PORT MAP (
			clk		=> clk,
			reset		=> reset,
			rd			=> tx_done_tick,
			wr			=> wr,
			w_data	=> w_data,
			empty		=> tx_empty,
			full		=> tx_full,
			r_data	=> tx_data
		);
end behavior;

