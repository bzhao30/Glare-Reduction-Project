library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_registers is
    Port ( clk      : in  STD_LOGIC;
           resend   : in  STD_LOGIC;
           advance  : in  STD_LOGIC;
           command  : out  std_logic_vector(15 downto 0);
           finished : out  STD_LOGIC);
end ov7670_registers;

architecture Behavioral of ov7670_registers is
    signal sreg   : std_logic_vector(15 downto 0);
    signal address : std_logic_vector(7 downto 0) := (others => '0');
begin
    command <= sreg;
    with sreg select finished  <= '1' when x"FFFF", '0' when others;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if resend = '1' then 
                address <= (others => '0');
            elsif advance = '1' then
                address <= std_logic_vector(unsigned(address)+1);
            end if;

            case address is
                when x"00" => sreg <= x"1280"; -- COM7   Reset
                when x"01" => sreg <= x"1280"; -- COM7   Reset
                when x"02" => sreg <= x"1100"; -- CLKRC  Prescaler - Fin/(1+1)
                when x"03" => sreg <= x"1204"; -- COM7   QIF image with RGB output
                when x"04" => sreg <= x"0C00"; -- COM3   Lots of stuff, enable scaling, all others off
                when x"05" => sreg <= x"3E00"; -- COM14  PCLK scaling off
                when x"06" => sreg <= x"4010"; -- COM15  Full 0-255 output, RGB 565
                when x"07" => sreg <= x"3A04"; -- TSLB   Set UV ordering, do not auto-reset window
                when x"08" => sreg <= x"8C00"; -- RGB444 Set RGB format
                when x"09" => sreg <= x"1711"; -- HSTART HREF start (high 8 bits)
                when x"0A" => sreg <= x"1861"; -- HSTOP  HREF stop (high 8 bits)
                when x"0B" => sreg <= x"32A4"; -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
                when x"0C" => sreg <= x"1903"; -- VSTART VSYNC start (high 8 bits)
                when x"0D" => sreg <= x"1A7B"; -- VSTOP  VSYNC stop (high 8 bits)
                when x"0E" => sreg <= x"030A"; -- VREF   VSYNC low two bits
                when x"0F" => sreg <= x"1500"; -- COM10 Use HREF not hSYNC
                when x"10" => sreg <= x"7A20"; -- SLOP
                when x"11" => sreg <= x"7B10"; -- GAM1
                when x"12" => sreg <= x"7C1E"; -- GAM2
                when x"13" => sreg <= x"7D35"; -- GAM3
                when x"14" => sreg <= x"7E5A"; -- GAM4
                when x"15" => sreg <= x"7F69"; -- GAM5
                when x"16" => sreg <= x"8076"; -- GAM6
                when x"17" => sreg <= x"8180"; -- GAM7
                when x"18" => sreg <= x"8288"; -- GAM8
                when x"19" => sreg <= x"838F"; -- GAM9
                when x"1A" => sreg <= x"8496"; -- GAM10
                when x"1B" => sreg <= x"85A3"; -- GAM11
                when x"1C" => sreg <= x"86AF"; -- GAM12
                when x"1D" => sreg <= x"87C4"; -- GAM13
                when x"1E" => sreg <= x"88D7"; -- GAM14
                when x"1F" => sreg <= x"89E8"; -- GAM15
                when x"20" => sreg <= x"13E5"; -- COM8 AGC Enable, AEC Enable
                when x"21" => sreg <= x"0000"; -- GAIN AGC
                when x"22" => sreg <= x"1000"; -- AECH Exposure
                when x"23" => sreg <= x"0D40"; -- COMM4 - Window Size
                when x"24" => sreg <= x"1418"; -- COMM9 AGC
                when x"25" => sreg <= x"A505"; -- AECGMAX banding filter step
                when x"26" => sreg <= x"2495"; -- AEW AGC Stable upper limit
                when x"27" => sreg <= x"2533"; -- AEB AGC Stable lower limit
                when x"28" => sreg <= x"26E3"; -- VPT AGC fast mode limits
                when x"29" => sreg <= x"9F78"; -- HRL High reference level
                when x"2A" => sreg <= x"A068"; -- LRL low reference level
                when x"2B" => sreg <= x"A103"; -- DSPC3 DSP control
                when x"2C" => sreg <= x"A6D8"; -- LPH Lower Prob High
                when x"2D" => sreg <= x"A7D8"; -- UPL Upper Prob Low
                when x"2E" => sreg <= x"A8F0"; -- TPL Total Prob Low
                when x"2F" => sreg <= x"A990"; -- TPH Total Prob High
                when x"30" => sreg <= x"AA94"; -- NALG AEC Algo select
                when x"31" => sreg <= x"13E5"; -- COM8 AGC Settings
                -- Flip the image vertically (mirror)
                when x"32" => sreg <= x"1E37"; -- MVFP Vertical flip
                when others => sreg <= x"FFFF"; -- STOP
            end case;
        end if;
    end process;
end Behavioral;
