library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity receiver is
port(
    clk : in std_logic;
    Rx : in std_logic;
    x_rpi : out integer;
    y_rpi : out integer;
    rpi_done : out std_logic);
end receiver;

architecture behavioral of receiver is

type statetype is (listen1, listen2, rx1, rx2, convert, done);
signal cs, ns : statetype := listen1;

signal x_sig, y_sig : integer := 0;
signal baudcount, bitcount: integer := 0;
signal baudtc, bittc, bauden, conven, rst, xreg, yreg, grand_rst: std_logic := '0';
signal data_x, data_y : std_logic_vector(7 downto 0) := (others => '0');

begin

------------------COUNTERS---------------
baudcounter : process(clk)
begin
if rising_edge(clk) then
if rst = '1' then
  baudcount <= 0;
end if;
if bauden = '1' then
  baudcount <= baudcount+1; 
  if baudcount = 1301 then
    baudcount <= 0;
  end if;       
end if;
end if;   

end process baudcounter;

process(baudcount) 
begin
if baudcount = 1301 then
    baudTC <= '1';
else
    baudTC <= '0';
end if;
end process;

bitcounter : process(clk)
begin

if rising_edge(clk) then
if rst = '1' then
  bitcount <= 0;
end if;
if baudTC = '1' then
  bitcount <= bitcount+1;    
  if bitcount = 8 then
    bitcount <= 0;
  end if;       
end if;
end if;


end process bitcounter;

process(baudcount, bitcount) 
begin
if bitcount = 8 and baudcount = 1301 then
  bitTC <= '1';
else
  bitTC <= '0';
end if;   
end process;

SR: process(clk) begin
if rising_edge(clk) then
    if grand_rst = '1' then
        data_x <= (others => '0');
        data_y <= (others => '0');
    end if;
    if baudtc = '1' and bittc = '0' then
    if xreg = '1' then
        data_x <= rx & data_x(7 downto 1);
    elsif yreg = '1' then
        data_y <= rx & data_y(7 downto 1);
    end if;
    end if;

end if;
end process;

process(conven) begin
    if conven = '1' then
        x_rpi <= to_integer(unsigned(data_x));
        y_rpi <= to_integer(unsigned(data_y));
    end if;
end process;
       
    


------------------FSM-----------------
stateupdate : process(clk) begin
if rising_edge(clk) then
    cs <= ns;
end if;
end process;

nextstatelogic: process(cs, rx, bittc) begin
ns <= cs;
rpi_done <= '0';
bauden <= '0';
conven <= '0';
rst <= '0';
xreg <= '0';
yreg <= '0';
grand_rst <= '0';

case cs is
    when listen1 =>
    grand_rst <= '1';
    rst <= '1';
    x_sig <= 0;
    y_sig <= 0;
    if rx = '0' then
        ns <= rx1;
    end if;
    when rx1 =>
    bauden <= '1';
    xreg <= '1';
    if bittc = '1' then
        ns <= listen2;
    end if;
    when listen2 =>
    rst <= '1';
    if rx = '0' then
        ns <= rx2;
    end if;
    when rx2 =>
    bauden <= '1';
    yreg <= '1';
    if bittc = '1' then
        ns <= convert;
    end if;
    when convert =>
    conven <= '1';
    ns <= done;
    when done =>
    rpi_done <= '1';
    ns <= listen1;
    when others => ns <= listen1;
end case;
end process;

end behavioral;