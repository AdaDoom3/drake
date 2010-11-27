with Ada;
procedure value is
	type Ordinal_Fixed is delta 0.1 range -100.0 .. 100.0;
	type Short_Fixed is delta 0.1 digits 2;
	type Long_Fixed is delta 0.1 digits 10;
	type Enum8 is (AAA, BBB, CCC);
	type Enum16 is (AAA, BBB, CCC);
	for Enum16 use (AAA => 0, BBB => 1, CCC => 16#ffff#);
	type Enum32 is (AAA, BBB, CCC);
	for Enum32 use (AAA => 0, BBB => 1, CCC => 16#ffffffff#);
	type Unsigned is mod 2 ** 8;
	type Long_Long_Unsigned is mod 2 ** Long_Long_Integer'Size;
	function "=" (Left, Right : Float) return Boolean is
	begin
		return abs (Left - Right) / Float'Max (abs Left, abs Right) < Float'Model_Epsilon * 100.0;
	end "=";
	function "=" (Left, Right : Long_Float) return Boolean is
	begin
		return abs (Left - Right) / Long_Float'Min (abs Left, abs Right) < Long_Float'Model_Epsilon * 100.0;
	end "=";
	function "=" (Left, Right : Long_Long_Float) return Boolean is
	begin
		return abs (Left - Right) / Long_Long_Float'Min (abs Left, abs Right) < Long_Long_Float'Model_Epsilon * 100.0;
	end "=";
begin
	pragma Assert (Boolean'Value (Boolean'Image (Boolean'First)) = Boolean'First);
	pragma Assert (Boolean'Value (Boolean'Image (Boolean'Last)) = Boolean'Last);
	pragma Assert (Enum8'Value (Enum8'Image (Enum8'First)) = Enum8'First);
	pragma Assert (Enum8'Value (Enum8'Image (Enum8'Last)) = Enum8'Last);
	pragma Assert (Enum16'Value (Enum16'Image (Enum16'First)) = Enum16'First);
	pragma Assert (Enum16'Value (Enum16'Image (Enum16'Last)) = Enum16'Last);
	pragma Assert (Enum32'Value (Enum32'Image (Enum32'First)) = Enum32'First);
	pragma Assert (Enum32'Value (Enum32'Image (Enum32'Last)) = Enum32'Last);
	pragma Assert (Character'Value (Character'Image (Character'First)) = Character'First);
	pragma Assert (Character'Value (Character'Image (Character'Last)) = Character'Last);
	pragma Assert (Wide_Character'Value (Wide_Character'Image (Wide_Character'First)) = Wide_Character'First);
	pragma Assert (Wide_Character'Value (Wide_Character'Image (Wide_Character'Last)) = Wide_Character'Last);
	pragma Assert (Wide_Wide_Character'Value ("Hex_00000000") = Wide_Wide_Character'First);
	pragma Assert (Wide_Wide_Character'Value ("Hex_7fffffff") = Wide_Wide_Character'Last);
	pragma Assert (Integer'Value (Integer'Image (Integer'First)) = Integer'First);
	pragma Assert (Integer'Value (Integer'Image (Integer'Last)) = Integer'Last);
	pragma Assert (Long_Long_Integer'Value (Long_Long_Integer'Image (Long_Long_Integer'First)) = Long_Long_Integer'First);
	pragma Assert (Long_Long_Integer'Value (Long_Long_Integer'Image (Long_Long_Integer'Last)) = Long_Long_Integer'Last);
	pragma Assert (Unsigned'Value (Unsigned'Image (Unsigned'First)) = Unsigned'First);
	pragma Assert (Unsigned'Value (Unsigned'Image (Unsigned'Last)) = Unsigned'Last);
	pragma Assert (Long_Long_Unsigned'Value (Long_Long_Unsigned'Image (Long_Long_Unsigned'First)) = Long_Long_Unsigned'First);
	pragma Assert (Long_Long_Unsigned'Value (Long_Long_Unsigned'Image (Long_Long_Unsigned'Last)) = Long_Long_Unsigned'Last);
	pragma Assert (Float'Value (Float'Image (Float'First)) = Float'First);
	pragma Assert (Float'Value (Float'Image (Float'Last)) = Float'Last);
	pragma Assert (Long_Float'Value (Long_Float'Image (Long_Float'First * 0.999999999999999)) = Long_Float'First);
	pragma Assert (Long_Float'Value (Long_Float'Image (Long_Float'Last * 0.999999999999999)) = Long_Float'Last);
	pragma Assert (Long_Long_Float'Value (Long_Long_Float'Image (Long_Long_Float'First * 0.999999999999999999)) = Long_Long_Float'First);
	pragma Assert (Long_Long_Float'Value (Long_Long_Float'Image (Long_Long_Float'Last * 0.999999999999999999)) = Long_Long_Float'Last);
	pragma Assert (Ordinal_Fixed'Value (Ordinal_Fixed'Image (Ordinal_Fixed'First)) = Ordinal_Fixed'First);
	pragma Assert (Ordinal_Fixed'Value (Ordinal_Fixed'Image (Ordinal_Fixed'Last)) = Ordinal_Fixed'Last);
	pragma Assert (Short_Fixed'Value (Short_Fixed'Image (Short_Fixed'First)) = Short_Fixed'First);
	pragma Assert (Short_Fixed'Value (Short_Fixed'Image (Short_Fixed'Last)) = Short_Fixed'Last);
	pragma Assert (Long_Fixed'Value (Long_Fixed'Image (Long_Fixed'First)) = Long_Fixed'First);
	pragma Assert (Long_Fixed'Value (Long_Fixed'Image (Long_Fixed'Last)) = Long_Fixed'Last);
	pragma Debug (Ada.Debug.Put ("OK"));
	null;
end value;
