----- VGA_FB
-- ECE 201 Final Project
-- Ramon Imbao
--
-- This project demonstrates an analog clock displayed through VGA.
-- The display is 640x480 but consists of a 240x240 (scaled to 2x) frame buffer
-- 	to limit the amount of 'memory' used.
--
-- WARNING: This project takes a long time (15+ mins) to compile on my PC equipped
-- with an Intel i3-2100! (phbbt)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity VGA_FB is
	port(
		CLOCK_50		: in std_logic;
		PB				: in std_logic_vector(3 downto 0);
		SW				: in std_logic_vector(9 downto 0);

		VGA_HS, VGA_VS			: out std_logic;
		VGA_R, VGA_G, VGA_B	: out std_logic_vector(3 downto 0));
end VGA_FB;

architecture rtl of VGA_FB is
	-- VGA

	constant H_VISIBLE	: integer := 640;
	constant H_FP			: integer := 16;
	constant H_SYNCPULSE	: integer := 96;
	constant H_BP			: integer := 48;
	constant H_TOTAL		: integer := H_VISIBLE + H_FP + H_SYNCPULSE + H_BP;
	
	constant V_VISIBLE	: integer := 480;
	constant V_FP			: integer := 10;
	constant V_SYNCPULSE	: integer := 2;
	constant V_BP			: integer := 33;
	constant V_TOTAL		: integer := V_VISIBLE + V_FP + V_SYNCPULSE + V_BP;
	
	signal XPOS				: integer range 1 to H_TOTAL;
	signal YPOS				: integer range 1 to V_TOTAL;
	
	signal CLOCK_25175	: std_logic;
	signal accumulator	: integer range -50000 to 50000 := 0;
	
	-- Frame buffer
	constant FB_SIZE		: integer := 240;
	constant FB_SIZE_0	: integer := FB_SIZE-1;
	
	type std_logic_vector_array is array((FB_SIZE-1) downto 0) of std_logic_vector((FB_SIZE-1) downto 0);
	signal framebuffer : std_logic_vector_array;
		
	signal XFB				: integer range 0 to FB_SIZE-1;
	signal YFB				: integer range 0 to FB_SIZE-1;
	
	-- Fonts
	-- taken from: http://www.rinkydinkelectronics.com/images/fonts/Retro8x16.png
	-- The last two lines of the 8x16 font are just black, so I didn't include them anymore.
	constant font_width		: integer := 8;
	constant font_height		: integer := 14;
	constant font_width_0	: integer := font_width-1;
	constant font_height_0	: integer := font_height-1;
	
	type fontchar_array is array(0 to font_height_0) of std_logic_vector(0 to font_width_0);
	
	constant char_0	: fontchar_array :=
		("00111100",
		 "00111100",
		 "01000010",
		 "01000010",
		 "01000110",
		 "01000110",
		 "01011010",
		 "01011010",
		 "01100010",
		 "01100010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100");
	
	constant char_1	: fontchar_array := 
		("00001000",
		 "00001000",
		 "00011000",
		 "00011000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00001000",
		 "00011100",
		 "00011100");

	constant char_2	: fontchar_array :=
		("00111100",
		 "00111100",
		 "01000010",
		 "01000010",
		 "00000010",
		 "00000010",
		 "00011100",
		 "00011100",
		 "00100000",
		 "00100000",
		 "01000000",
		 "01000000",
		 "01111110",
		 "01111110");
	
	constant char_3	: fontchar_array :=
		("01111110",
		 "01111110",
		 "00000010",
		 "00000010",
		 "00000100",
		 "00000100",
		 "00011100",
		 "00011100",
		 "00000010",
		 "00000010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100");
		 
	constant char_4	: fontchar_array :=
		("00000100",
		 "00000100",
		 "00001100",
		 "00001100",
		 "00010100",
		 "00010100",
		 "00100100",
		 "00100100",
		 "01111110",
		 "01111110",
		 "00000100",
		 "00000100",
		 "00000100",
		 "00000100");
		 
	constant char_5	: fontchar_array :=
		("01111110",
		 "01111110",
		 "01000000",
		 "01000000",
		 "01111100",
		 "01111100",
		 "00000010",
		 "00000010",
		 "00000010",
		 "00000010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100");

	constant char_6	: fontchar_array :=
		("00011110",
		 "00011110",
		 "00100000",
		 "00100000",
		 "01000000",
		 "01000000",
		 "01111100",
		 "01111100",
		 "01000010",
		 "01000010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100");
		 
	constant char_7	: fontchar_array :=
		("01111110",
		 "01111110",
		 "00000010",
		 "00000010",
		 "00000100",
		 "00000100",
		 "00001000",
		 "00001000",
		 "00010000",
		 "00010000",
		 "00010000",
		 "00010000",
		 "00010000",
		 "00010000");
		 
	constant char_8	: fontchar_array :=
		("00111100",
		 "00111100",
		 "01000010",
		 "01000010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100",
		 "01000010",
		 "01000010",
		 "01000010",
		 "01000010",
		 "00111100",
		 "00111100");
		
	constant char_9	: fontchar_array :=
		("00111100",
		 "00111100",
		 "01000010",
		 "01000010",
		 "01000010",
		 "01000010",
		 "00111110",
		 "00111110",
		 "00000010",
		 "00000010",
		 "00000100",
		 "00000100",
		 "01111000",
		 "01111000");

	-- Hands
	type trig_LUT is array(0 to 59) of integer range -FB_SIZE to FB_SIZE;
	-- NOTE: These LUTs go from -90 to 270 rather than 0 to 360
	constant sin_LUT : trig_LUT := (-100,-100,-98,-96,-92,-87,-81,-75,-67,-59,-50,-41,-31,-21,-11,0,10,20,30,40,50,58,66,74,80,86,91,95,97,99,100,99,97,95,91,86,80,74,66,58,50,40,30,20,10,0,-11,-21,-31,-41,-50,-59,-67,-75,-81,-87,-92,-96,-98,-100);
	constant cos_LUT : trig_LUT := (0,10,20,30,40,50,58,66,74,80,86,91,95,97,99,100,99,97,95,91,86,80,74,66,58,50,40,30,20,10,0,-11,-21,-31,-41,-50,-59,-67,-75,-81,-87,-92,-96,-98,-100,-100,-100,-98,-96,-92,-87,-81,-75,-67,-59,-50,-41,-31,-21,-11);
		
	signal hours	: integer range 0 to 11 := 0;
	signal minutes	: integer range 0 to 59 := 0;
	signal seconds	: integer range 0 to 59 := 0;
	
begin
	
	process(CLOCK_50)
		constant radius	: integer := 100;
		constant x0			: integer := 120;
		constant y0			: integer := 120;
		constant minx		: integer := -radius;
		constant maxx		: integer := radius;
		constant miny		: integer := -radius;
		constant maxy		: integer := radius;
		constant r_inner	: integer := 98;
		
		constant hour_length		: integer := 57;
		constant minute_length	: integer := 70;
		constant second_length		: integer := 90;
		
		variable count		: integer range 1 to 50000000 := 1;
		
		variable canPress	: std_logic_vector(3 downto 0) := "1111";
	begin
		if (SW(9) = '0') then
			if (rising_edge(CLOCK_50)) then
			-- 1 second timer
				if (count < 50000000) then
					count := count + 1;
				else
					if (seconds < 59) then
						seconds <= seconds + 1;
					else
						if (minutes < 59) then
							minutes <= minutes + 1;
						else
							if (hours < 11) then
								hours <= hours + 1;
							else
								hours <= 0;
							end if;
							minutes <= 0;
						end if;
						seconds <= 0;
					end if;
					
					count := 1;
				end if;
			
				-- Handle 25.175 clock
				if (accumulator < 0) then
					accumulator <= accumulator + 2000 - 1007;
					CLOCK_25175 <= '1';
				else
					accumulator <= accumulator - 1007;
					CLOCK_25175 <= '0';
				end if;
				
				-- Clear buffer
				for Y in 0 to FB_SIZE_0 loop
					for X in 0 to FB_SIZE_0 loop
						framebuffer(Y) (X) <= '0';
					end loop;
				end loop;
				
				-- Handle elements in framebuffer
				-- Circle
				for Y in miny to maxy loop
					for X in minx to maxx loop
						if ((X*X) + (Y*Y) <= (radius*radius) and (X*X) + (Y*Y) >= (r_inner*r_inner)) then
							framebuffer(Y+y0) (X+x0) <= '1';
						end if;
					end loop;
				end loop;
				
				-- Numbers
				for Y in 0 to font_height_0 loop
					for X in 0 to font_width_0 loop
						-- 12
						if (char_1(Y) (X) = '1') then
							framebuffer(Y+28) (X+110) <= '1';
						end if;
						if (char_2(Y) (X) = '1') then
							framebuffer(Y+28) (X+120) <= '1';
						end if;
						-- 6
						if (char_6(Y) (X) = '1') then
							framebuffer(Y+200) (X+115) <= '1';
						end if;
						
						-- 3
						if (char_3(Y) (X) = '1') then
							framebuffer(Y+114)(X+205) <= '1';
						end if;
						-- 9
						if (char_9(Y) (X) = '1') then
							framebuffer(Y+114)(X+30) <= '1';
						end if;
						
						-- 1
						if (char_1(Y) (X) = '1') then
							framebuffer(Y+39)(X+158) <= '1';
						end if;
						-- 7
						if (char_7(Y) (X) = '1') then
							framebuffer(Y+184)(X+74) <= '1';
						end if;
						
						-- 2
						if (char_2(Y) (X) = '1') then
							framebuffer(Y+70)(X+188) <= '1';
						end if;
						-- 8
						if (char_8(Y) (X) = '1') then
							framebuffer(Y+154)(X+43) <= '1';
						end if;
						
						-- 4
						if (char_4(Y) (X) = '1') then
							framebuffer(Y+154)(X+188) <= '1';
						end if;
						-- 10
						if (char_1(Y) (X) = '1') then
							framebuffer(Y+70)(X+39) <= '1';
						end if;
						if (char_0(Y) (X) = '1') then
							framebuffer(Y+70)(X+47) <= '1';
						end if;
						
						-- 5
						if (char_5(Y) (X) = '1') then
							framebuffer(Y+184)(X+158) <= '1';
						end if;
						-- 11
						if (char_1(Y) (X) = '1') then
							framebuffer(Y+39)(X+70) <= '1';
							framebuffer(Y+39)(X+78) <= '1';
						end if;
						
					end loop;
				end loop;

				-- Clock hands and markers
				for len in 1 to second_length+5 loop
					for n in 0 to 59 loop
						if (len > second_length+2 and len <= second_length+5) then
							framebuffer(sin_LUT(n)*len/100 + 120) (cos_LUT(n)*len/100 + 120) <= '1';
						end if;
					
						if (len <= second_length) then
							if (n = seconds) then
								framebuffer(sin_LUT(n)*len/100 + 120) (cos_LUT(n)*len/100 + 120) <= '1';
							end if;
						end if;
						
						if (len <= minute_length) then
							if (n = minutes) then
								framebuffer(sin_LUT(n)*len/100 + 120) (cos_LUT(n)*len/100 + 120) <= '1';
							end if;
							
							if (len <= hour_length) then
								if (n = hours*5 + minutes/12) then
									framebuffer(sin_LUT(n)*len/100 + 120) (cos_LUT(n)*len/100 + 120) <= '1';
								end if;
							end if;
						end if;
					end loop;
				end loop;
				
				-- Minute Adjust +
				if (PB(0) = '0') then
					if (canPress(0) = '1') then
						if (minutes < 59) then
							minutes <= minutes + 1;
						else
							minutes <= 0;
						end if;
						
						canPress(0) := '0';
					end if;
				else
					canPress(0) := '1';
				end if;
				
				-- Minute Adjust -
				if (PB(1) = '0') then
					if (canPress(1) = '1') then
						if (minutes > 0) then
							minutes <= minutes - 1;
						else
							minutes <= 59;
						end if;
						canPress(1) := '0';
					end if;
				else
					canPress(1) := '1';
				end if;
				
				-- Hour Adjust +
				if (PB(2) = '0') then
					if (canPress(2) = '1') then
						if (hours < 11) then
							hours <= hours + 1;
						else
							hours <= 0;
						end if;
						canPress(2) := '0';
					end if;
				else
					canPress(2) := '1';
				end if;
				
				-- Hour Adjust -
				if (PB(3) = '0') then
					if (canPress(3) = '1') then
						if (hours > 0) then
							hours <= hours - 1;
						else
							hours <= 11;
						end if;
						canPress(3) := '0';
					end if;
				else
					canPress(3) := '1';
				end if;
				
			end if;
		else
			-- Reset
			count := 1;
			seconds <= 0;
			minutes <= 0;
			hours <= 0;
			accumulator <= 0;
		end if;
	end process;
	
	process(CLOCK_25175)
	begin
		if (rising_edge(CLOCK_25175)) then
			-- HSYNC
			if (XPOS >= H_VISIBLE + H_FP and XPOS <= H_VISIBLE + H_FP + H_SYNCPULSE) then
				VGA_HS <= '0';
			else
				VGA_HS <= '1';
			end if;
			
			-- VSYNC
			if (YPOS >= V_VISIBLE + V_FP and YPOS <= V_VISIBLE+ V_FP + V_SYNCPULSE) then
				VGA_VS <= '0';
			else
				VGA_VS <= '1';
			end if;
			
			-- Display
			if (XPOS >= 80 and XPOS <= H_VISIBLE-80 and YPOS >= 0 and YPOS <= V_VISIBLE) then
				XFB <= (XPOS - 80) / 2;
				YFB <= YPOS / 2;
				
				if (framebuffer(YFB) (XFB) = '0') then
					VGA_R <= "0000";
					VGA_G <= "0000";
					VGA_B <= "0000";
				else
					VGA_R <= "1111";
					VGA_G <= "1111";
					VGA_B <= "1111";
				end if;
			else
				-- Make sure it's 0
				VGA_R <= "0000";
				VGA_G <= "0000";
				VGA_B <= "0000";
			end if;
			
			-- Position increment
			if (XPOS < H_TOTAL) then
				XPOS <= XPOS + 1;
			else
				XPOS <= 1;
				if (YPOS < V_TOTAL) then
					YPOS <= YPOS + 1;
				else
					YPOS <= 1;
				end if;
			end if;
		end if;
	end process;
end rtl;