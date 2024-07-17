library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity downsample is
    Port (
        clk      : in  STD_LOGIC; -- ov7670_pclk
        addr_in  : in  STD_LOGIC_VECTOR (16 downto 0); -- address to read data
        data_in  : in  STD_LOGIC_VECTOR (3 downto 0);  -- 4-bit input data
        addr_out : out STD_LOGIC_VECTOR (16 downto 0);
        data_out : out STD_LOGIC_VECTOR (3 downto 0);  -- 3-bit grayscale output
        we_out   : out STD_LOGIC
    );
end downsample;

architecture Behavioral of downsample is
    constant BLOCK_SIZE : integer := 10;
    signal x_count      : integer range 0 to BLOCK_SIZE-1 := 0;
    signal y_count      : integer range 0 to BLOCK_SIZE-1 := 0;
    signal write_addr   : integer := 0;
    signal reset        : std_logic := '0';
    signal done         : std_logic := '0';
    signal we_internal  : std_logic := '0';
    signal processing   : std_logic := '0';
    type statetype is (init, inprogress, finish);
    signal cs, ns : statetype := init;
begin
    -- Main process handling pixel downsampling
    process(clk)
    variable pixel_sum, pixel_count, avg_pixel : integer := 0;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                x_count <= 0;
                y_count <= 0;
                pixel_sum := 0;
                pixel_count := 0;
                write_addr <= 0;
            end if;

            if processing = '1' then
                pixel_sum := pixel_sum + to_integer(unsigned(data_in));
                pixel_count := pixel_count + 1;

                x_count <= x_count + 1;
                if x_count = BLOCK_SIZE-1 then
                    x_count <= 0;
                    y_count <= y_count + 1;

                    if y_count = BLOCK_SIZE-1 then
                        y_count <= 0;
                        -- Compute the average
                        avg_pixel := pixel_sum / (BLOCK_SIZE * BLOCK_SIZE);
                        -- Convert to 3-bit grayscale
                        case avg_pixel is
                            when 0 to 31    => data_out <= "0000";
                            when 32 to 63   => data_out <= "0010";
                            when 64 to 95   => data_out <= "0100";
                            when 96 to 127  => data_out <= "0110";
                            when 128 to 159 => data_out <= "1000";
                            when 160 to 191 => data_out <= "1010";
                            when 192 to 223 => data_out <= "1100";
                            when others     => data_out <= "1110";
                        end case;

                        addr_out <= std_logic_vector(to_unsigned(write_addr, 17));
                        write_addr <= write_addr + 1;
                        we_internal <= '1';  -- Assert write enable

                        -- Reset the sum and count for the next block
                        pixel_sum := 0;
                        pixel_count := 0;
                    else
                        we_internal <= '0';  -- Deassert write enable
                    end if;
                else
                    we_internal <= '0';  -- Deassert write enable
                end if;
            end if;
        end if;
    end process;

    -- State transition process
    process(clk)
    begin
        if rising_edge(clk) then
            cs <= ns;
        end if;
    end process;

    -- State control process
    process(cs, addr_in)
    begin
        ns <= cs;
        reset <= '0';
        done <= '0';
        processing <= '0';
        case cs is
            when init =>
                reset <= '1';
                ns <= inprogress;

            when inprogress =>
                processing <= '1';  -- Assert processing only in this state
                if unsigned(addr_in) = 76800 then
                    ns <= finish;
                end if;

            when finish =>
                ns <= init;
                done <= '1';

            when others =>
                ns <= init;
        end case;
    end process;

    -- Ensure we_out is only driven here
    we_out <= we_internal;

end Behavioral;
