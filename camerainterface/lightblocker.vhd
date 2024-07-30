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

type statetype is (idle, finddist, findcoords, findlocation);
signal cs, ns : statetype := idle;
signal distdone, locdone, rst : std_logic := '0';
signal coordsen, disten, locen : std_logic := '0';
signal facedist : sfixed(5 downto -6) := "000000101101"; --0.7m
signal cardist : sfixed(5 downto -6) := "000001000000"; --1m
signal disparity : sfixed(5 downto -6) := (others => '0');
--signal baseline : sfixed(5 downto -6) := "000000010011"; -- 0.3m
-- TEMPORARY CONSTANT TO BE ADJUSTED EMPIRICALLY FOR DISPARITY-DISTANCE CALCULATION
signal constantvar : sfixed(5 downto -6) := "111100000000"; -- 60 
signal rpi_x, rpi_y, fpga_x, fpga_y : sfixed(5 downto -6) := (others => '0');
-- DISTANCE BETWEEN USER AND SCREEN IS APPROXIMATED AS 0.42 M
signal rpi_dist : sfixed(5 downto -6) := to_sfixed(0.42, 5, -6);

begin

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
                disparity <= to_sfixed(x_l-x_r, 5, -6);
            else 
                disparity <= to_sfixed(x_r-x_l, 5, -6);
            end if;    
        when 2 => 
            cardist <= resize(constantvar/disparity, 5, -6);
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
        rpi_x <= resize(to_sfixed((x_rpi-50), 5, -6) * to_sfixed(0.01, 5, -6), 5, -6); -- WILL NEED TO ADJUST ACCORDINGLY LATER
        -- rpi_y <= 0 assuming head horizontal
    end if;    
end if;
end process;

fpgacoord : process(clk) begin
if rising_edge(clk) then
    if coordsen = '1' then
        -- ((x1 - 60) + (x2-60))/2 * distance
        fpga_x <= resize((to_sfixed((x_l - 80) + (x_r - 80), 5, -6) * to_sfixed(0.5, 5, -6)) * cardist, 5, -6); -- NEED TO MULTIPLY BY CONSTANT
        -- must subtract all by 0.16m
        fpga_y <= resize((to_sfixed((y_l) + (y_r), 5, -6) * to_sfixed(0.5, 5, -6)) * cardist, 5, -6) - to_sfixed(0.16, 5, -6); -- NEED TO MULTIPLY BY CONSTANT
    end if;
end if;
end process;

location : process(clk) begin
if rising_edge(clk) then
if locen = '1' then
        x_blocker <= to_integer(resize(rpi_x + (fpga_x - rpi_x) * rpi_dist / (cardist + rpi_dist), 10, -6) * to_sfixed(680, 10, -6));
        y_blocker <= to_integer(resize((fpga_y) * rpi_dist / (cardist + rpi_dist), 10, -6) * to_sfixed(510, 10, -6));
end if;
end if;
end process;
---------------FSM---------------------
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
    if locdone = '1' then
        ns <= idle;
    end if;
    when others => ns <= idle;
end case;
end process;

end Behavioral;
