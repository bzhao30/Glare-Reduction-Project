library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Brightspot is
    Port (
        clk         : in  STD_LOGIC;
        addrb       : in STD_LOGIC_VECTOR(14 downto 0); -- Updated to 15 bits
        doutb       : in  STD_LOGIC_VECTOR(3 downto 0);
        activeArea  : in  STD_LOGIC;  -- Active area signal from VGA module
        avg_x       : out integer;
        avg_y       : out integer
    );
end Brightspot;

architecture Behavioral of Brightspot is
    signal x_sum        : unsigned(15 downto 0) := (others => '0');
    signal y_sum        : unsigned(15 downto 0) := (others => '0');
    signal white_count  : unsigned(15 downto 0) := (others => '0');
    signal current_addr : unsigned(14 downto 0); -- Updated to 15 bits
    signal x_coord      : unsigned(7 downto 0);
    signal y_coord      : unsigned(6 downto 0); -- Updated to 7 bits
begin

    -- Coordinate calculation based on address
    process(clk)
    begin
        if rising_edge(clk) then
            if activeArea = '1' then
                current_addr <= unsigned(addrb);

                x_coord <= current_addr(7 downto 0);    -- X-coordinate (8 bits)
                y_coord <= current_addr(14 downto 8);   -- Y-coordinate (7 bits)

                if doutb = "1111" or doutb = "1110" then  -- Assuming "1111" represents a white pixel
                    x_sum <= x_sum + unsigned(x_coord);
                    y_sum <= y_sum + unsigned(y_coord);
                    white_count <= white_count + 1;
                end if;
            end if;
        end if;
    end process;

    -- Calculate average position
    process(clk)
    begin
        if rising_edge(clk) then
            if white_count > "0000000000001111" then
                avg_x <= to_integer(x_sum / white_count);
                avg_y <= to_integer(y_sum / white_count);
            else
                avg_x <= 80;
                avg_y <= 60;
            end if;
        end if;
    end process;

end Behavioral;
