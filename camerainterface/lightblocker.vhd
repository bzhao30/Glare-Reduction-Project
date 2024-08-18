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
signal facedist : sfixed(11 downto -6) := "000000000000101101"; --0.7m
signal cardist : sfixed(11 downto -6) := "000000000001000000"; --1m
signal disparity : sfixed(11 downto -6) := (others => '0');
--signal baseline : sfixed(5 downto -6) := "000000010011"; -- 0.3m
-- TEMPORARY CONSTANT TO BE ADJUSTED EMPIRICALLY FOR DISPARITY-DISTANCE CALCULATION
signal rpi_x, rpi_y, fpga_x, fpga_y: sfixed(11 downto -6) := (others => '0');
signal rpi_x_final, rpi_y_final, fpga_x_final, fpga_y_final : integer := 0;
-- DISTANCE BETWEEN USER AND SCREEN IS APPROXIMATED AS 0.42 M
signal rpi_dist : sfixed(11 downto -6) := to_sfixed(0.42, 11, -6);


begin

uuX: lookuptable port map(
    input => fpga_x(11 downto 0),
    output => fpga_x_final);
uuY: lookuptable port map(
    input => fpga_y(11 downto 0),
    output => fpga_y_final);
    

disparite : process(clk)
variable pipeline_count : integer := 0;
begin
if rising_edge(clk) then
if rst = '1' then
    pipeline_count := 0;
end if;
if disten = '1' then
    pipeline_count := pipeline_count + 1;
    case pipeline_count is
        when 1 => 
            if x_l > x_r then
                disparity <= to_sfixed(x_l-x_r, 11, -6);
            else 
                disparity <= to_sfixed(x_r-x_l, 11, -6);
            end if;    
        when 2 => 
            if disparity = "000000000000000000" then
                cardist <= "011111111111111111";
            else
                cardist <= resize(1/disparity, 11, -6);
            end if;
        when 3 => 
            distdone <= '1';
        when others =>
    end case;    
end if;    
end if;
end process;

rpicoord : process(clk) begin
if rising_edge(clk) then
    if coordsen = '1' then
        rpi_x <= resize(to_sfixed((x_rpi-110), 11, -6) * to_sfixed(1, 11, -6), 11, -6); -- WILL NEED TO ADJUST ACCORDINGLY LATER
        
        rpi_y <= to_sfixed(-50, 11, -6);
    end if;    
end if;
end process;

fpgacoord : process(clk)
begin
    if rising_edge(clk) then
        if coordsen = '1' then
            -- ((x1 - 80) + (x2 - 80)) / 2 * distance
            FPGA_x <= resize((to_sfixed((x_l*2)/2, 11, -6)) - to_sfixed(132, 11, -6), 11, -6); -- atm testing why x axis shaky
            -- ((y1) + (y2)) / 2 * distance - 0.16
            FPGA_y <= resize((to_sfixed(y_l, 11, -6) + to_sfixed(y_r, 11, -6)) - to_sfixed(30, 11, -6), 11, -6);

        end if;
    end if;
end process;

location : process(clk)
begin
if rising_edge(clk) then
if locen = '1' then
    -- for temporary rpi testing purposes: 
    x_blocker <= fpga_x_final*3;
    --y_blocker <= 2*y_l;
    --x_blocker <= to_integer(resize(rpi_x + (fpga_x - rpi_x) * rpi_dist / (cardist + rpi_dist), 11, -6) );
    --y_blocker <= to_integer(resize((fpga_y) * rpi_dist / (cardist + rpi_dist), 11, -6) );
    y_blocker <= fpga_y_final*5;
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
    if distdone = '1' then
        ns <= findcoords;
    end if;
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
