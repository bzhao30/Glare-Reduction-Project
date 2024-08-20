library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.fixed_pkg.all;

entity lightblocker is
port(
    clk : in std_logic;
    en : in std_logic;
    x_l : in integer;
    x_r : in integer;
    y_l : in integer;
    y_r : in integer;
    x_rpi : in integer;
    y_rpi : in integer;
    cardisthex   : out std_logic_vector(15 downto 0);
    x_blocker : out integer;
    y_blocker : out integer);
    
end lightblocker;

-- Formula to be empirically measured
-- 1/disparity * constant
architecture Behavioral of lightblocker is

component lookuptable is
port(
    input : in sfixed(11 downto 0);
    output : out integer);
end component;

type statetype is (idle, finddist, findcoords, findlocation);
signal cs, ns : statetype := idle;
signal distdone, locdone, rst : std_logic := '0';
signal coordsen, disten, locen : std_logic := '0';
signal facedist : sfixed(11 downto -4) := "0000000000001011"; --0.7m
signal cardist : sfixed(11 downto -4) := "0000000000010000"; --1m
--signal baseline : sfixed(5 downto -4) := "000000010011"; -- 0.3m
-- TEMPORARY CONSTANT TO BE ADJUSTED EMPIRICALLY FOR DISPARITY-DISTANCE CALCULATION
signal rpi_x, rpi_y, fpga_x, fpga_y: sfixed(11 downto -4) := (others => '0');
signal rpi_x_final, rpi_y_final, fpga_x_final, fpga_y_final : integer := 0;
-- DISTANCE BETWEEN USER AND SCREEN IS APPROXIMATED AS 0.42 M
signal rpi_dist : sfixed(11 downto -4) := to_sfixed(0.42, 11, -4);


begin

uuX: lookuptable port map(
    input => fpga_x(11 downto 0),
    output => fpga_x_final);
uuY: lookuptable port map(
    input => fpga_y(11 downto 0),
    output => fpga_y_final);
    

disparite : process(clk)
variable disparity : sfixed(11 downto -4) := (others => '0');
begin
if rising_edge(clk) then
    if disten = '1' then
        if x_l = x_r then
            cardist <= "0111111111111111";
        elsif x_l > x_r then
            disparity := to_sfixed(x_l-x_r, 11, -4);
            cardist <= resize(50/disparity, 11, -4);
        else
            disparity := to_sfixed(x_r-x_l, 11, -4);
            cardist <= resize(6000/disparity, 11, -4);
        end if;      
    end if;    
end if;
end process;
cardisthex <= std_logic_vector(to_signed(cardist, cardisthex'length));

rpicoord : process(x_rpi) begin
    rpi_x <= resize(to_sfixed((x_rpi-110), 11, -4) * to_sfixed(1, 11, -4), 11, -4); -- WILL NEED TO ADJUST ACCORDINGLY LATER
    
    rpi_y <= to_sfixed(-50, 11, -4);
end process;

fpgacoord : process(clk)
begin
    if rising_edge(clk) then
        if coordsen = '1' then
            -- ((x1 - 80) + (x2 - 80)) / 2 * distance
            FPGA_x <= resize((to_sfixed((x_l + x_r)/2, 11, -4)) - to_sfixed(0, 11, -4), 11, -4); -- atm testing why x axis shaky
            -- ((y1) + (y2)) / 2 * distance - 0.16
            FPGA_y <= resize((to_sfixed(y_l, 11, -4) + to_sfixed(y_r, 11, -4)) - to_sfixed(0, 11, -4), 11, -4);

        end if;
    end if;
end process;

location : process(clk)
begin
if rising_edge(clk) then
if locen = '1' then
    -- for temporary rpi testing purposes: 
    x_blocker <= (FPGA_X_final);
    --y_blocker <= 2*y_l;
    --x_blocker <= to_integer(resize(rpi_x + (fpga_x - rpi_x) * rpi_dist / (cardist + rpi_dist), 11, -4) );
    --y_blocker <= to_integer(resize((fpga_y) * rpi_dist / (cardist + rpi_dist), 11, -4) );
    y_blocker <= fpga_y_final;
end if;
end if;
end process;
---------------FSM-------------------S--
stateupdate : process(clk) begin
if rising_edge(clk) then
    cs <= ns;
end if;
end process;

nextstatelogic : process(cs, en, distdone, locdone) begin
ns <= cs;
coordsen <= '0';
disten <= '0';
locen <= '0';
rst <= '0';

case cs is 
    when idle =>
    rst <= '1';
    if en = '1' then
        ns <= finddist;
    end if;
    when finddist => 
    disten <= '1';
    ns <= findcoords;
    when findcoords =>
    coordsen <= '1';
    ns <= findlocation;
    when findlocation =>
    locen <= '1';
    ns <= idle;
    when others => ns <= idle;
end case;
end process;

end Behavioral;
