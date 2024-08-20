library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity mux7seg is
    Port (
        clk_port    : in  std_logic;                        -- runs on a fast (25 MHz) clock
        y3_port     : in  std_logic_vector (3 downto 0);    -- digits
        y2_port     : in  std_logic_vector (3 downto 0);    -- digits
        y1_port     : in  std_logic_vector (3 downto 0);    -- digits
        y0_port     : in  std_logic_vector (3 downto 0);    -- digits
        dp_set_port : in  std_logic_vector(3 downto 0);     -- decimal points
        seg_port    : out std_logic_vector(0 to 6);         -- segments (a...g)
        dp_port     : out std_logic;                        -- decimal point
        an_port     : out std_logic_vector (3 downto 0)     -- anodes
    );
end mux7seg;

architecture Behavioral of mux7seg is
    -- Constants
    constant CLK_DIVIDER_MAX: unsigned(14 downto 0) := to_unsigned(24999, 15);  -- 25 MHz / 25000 = 1 kHz (for 1 ms refresh per digit)
    
    -- Signals
    signal cdcount: unsigned(14 downto 0) := (others => '0');   -- clock divider counter register
    signal CE : std_logic := '0';                               -- clock enable signal for multiplexing

    signal adcount : unsigned(1 downto 0) := "00";              -- anode / digit selector count
    signal muxy : std_logic_vector(3 downto 0);                 -- selected digit
    signal segh : std_logic_vector(0 to 6);                     -- segments (high true)

begin
    -- Clock Divider Process
    ClockDivider: process(clk_port)
    begin
        if rising_edge(clk_port) then
            if cdcount = CLK_DIVIDER_MAX then
                cdcount <= (others => '0');
                CE <= '1';  -- Toggle clock enable signal every 1 ms
            else
                cdcount <= cdcount + 1;
                CE <= '0';
            end if;
        end if;
    end process ClockDivider;

    -- Anode Driver Process
    AnodeDriver: process(clk_port, adcount)
    begin
        if rising_edge(clk_port) then
            if CE = '1' then
                adcount <= adcount + 1;  -- Cycle through the digits
            end if;
        end if;

        case adcount is
            when "00" => an_port <= "1110"; muxy <= y0_port; dp_port <= '1';
            when "01" => an_port <= "1101"; muxy <= y1_port; dp_port <= '0';
            when "10" => an_port <= "1011"; muxy <= y2_port; dp_port <= '1';
            when "11" => an_port <= "0111"; muxy <= y3_port; dp_port <= '1';
            when others => an_port <= "1111";  -- Default (all digits off)
        end case;
    end process AnodeDriver;

    -- Seven-Segment Decoder Process
    process(muxy)
    begin
        case muxy is
            when "0000" => segh <= "1111110";  -- 0
            when "0001" => segh <= "0110000";  -- 1
            when "0010" => segh <= "1101101";  -- 2
            when "0011" => segh <= "1111001";  -- 3
            when "0100" => segh <= "0110011";  -- 4
            when "0101" => segh <= "1011011";  -- 5
            when "0110" => segh <= "1011111";  -- 6
            when "0111" => segh <= "1110000";  -- 7
            when "1000" => segh <= "1111111";  -- 8
            when "1001" => segh <= "1111011";  -- 9
            when "1010" => segh <= "1110111";  -- A
            when "1011" => segh <= "0011111";  -- b
            when "1100" => segh <= "1001110";  -- C
            when "1101" => segh <= "0111101";  -- d
            when "1110" => segh <= "1001111";  -- E
            when "1111" => segh <= "1000111";  -- F
            when others => segh <= "0000000";  -- All off (default)
        end case;
    end process;

    -- Assign inverted segment signals for common anode display
    seg_port <= not(segh);

end Behavioral;
