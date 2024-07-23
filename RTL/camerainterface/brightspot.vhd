library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Brightspot is
    Port (
        clk         : in  STD_LOGIC;
        addrb       : in STD_LOGIC_VECTOR(14 downto 0); 
        doutb       : in  STD_LOGIC_VECTOR(3 downto 0);
        activeArea  : in  STD_LOGIC;  -- Active area signal from VGA module
        avg_x       : out integer;
        avg_y       : out integer
    );
end Brightspot;

architecture Behavioral of Brightspot is
    signal x_sum        : unsigned(15 downto 0) := (others => '0');
    signal y_sum        : unsigned(15 downto 0) := (others => '0');
    signal white_count  : unsigned(15 downto 0) := "0000000000000000";
    signal current_addr , prev_addr: unsigned(14 downto 0) := (others => '0'); 
    type statetype is (init, read, calc);
    signal cs, ns : statetype := init;
    signal rst, calcen : std_logic := '0';
    signal xsig : integer := 80;
    signal ysig : integer := 60;
begin
    current_addr <= unsigned(addrb);

    -- Coordinate calculation based on address
    process(clk)
    variable x_coord      : unsigned(7 downto 0);
    variable y_coord      : unsigned(6 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                x_coord := (others => '0');
                y_coord := (others => '0');
                x_sum <= (others => '0');
                y_sum <= (others => '0');
            end if;
            
            if activeArea = '1' then

                x_coord := current_addr(7 downto 0);    -- X-coordinate (8 bits)
                y_coord := current_addr(14 downto 8);   -- Y-coordinate (7 bits)
                prev_addr <= current_addr;
                if prev_addr /= current_addr then
                    if doutb = "1111" or doutb = "1110" then  
                        x_sum <= x_sum + ("00000000" & (x_coord));
                        y_sum <= y_sum + ("000000000" & (y_coord));
                        white_count <= white_count + 1;
                end if;
                end if;
            end if;
        end if;
    end process;

    -- Calculate average position
    process(clk)
    begin
        if rising_edge(clk) then
            if calcen = '1' then
                if white_count > "0000000000001111" then
                    xsig <= to_integer((x_sum + white_count / 2) / white_count);
                    ysig <= to_integer((y_sum + white_count / 2) / white_count);
                end if;
            end if;
        end if;
    end process;
    avg_x <= xsig;
    avg_y <= ysig;
    
    stateupdate : process(clk) begin
    if rising_edge(clk) then
        cs <= ns;
    end if;
    end process;
    
    nextstate: process(cs, activeArea) begin
        rst<= '0';
        calcen <= '0';
        case cs is 
            when init =>
                rst <= '1';
                if activeArea = '1' then
                    ns <= read;
                end if;
            when read =>
                if activeArea = '0' then
                    ns <= calc;
                end if;
            when calc =>
                calcen <= '1';
                ns <= init;
            when others => ns <= init;
        end case;
    end process;
                
        

end Behavioral;
