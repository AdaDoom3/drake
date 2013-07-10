with Ada.Streams;
with Ada.Streams.Buffer_Storage_IO;
with System.Native_Encoding;
with System.Native_Encoding.Names;
with System.Native_Encoding.Strings;
with System.Native_Encoding.Wide_Strings;
with System.Native_Encoding.Wide_Wide_Strings;
with System.Native_Encoding.Encoding_Streams;
procedure nls is
	use type Ada.Streams.Stream_Element_Array;
	use type Ada.Streams.Stream_Element_Offset;
	Japanease_A : constant String := (
		Character'Val (16#e3#),
		Character'Val (16#81#),
		Character'Val (16#82#));
begin
	-- status check
	declare
		E : System.Native_Encoding.Strings.Encoder;
		pragma Warnings (Off, E);
	begin
		if System.Native_Encoding.Strings.Encode (E, "") = (1 .. 0 => <>) then
			null;
		end if;
		raise Program_Error; -- bad
	exception
		when System.Native_Encoding.Status_Error =>
			null;
	end;
	-- decoding
	declare
		D : System.Native_Encoding.Strings.Decoder :=
			System.Native_Encoding.Strings.From (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Strings.Decode (D, (1 .. 0 => <>)) = "");
		pragma Assert (System.Native_Encoding.Strings.Decode (D, (1 => 16#41#)) = "A");
		pragma Assert (System.Native_Encoding.Strings.Decode (D, (16#41#, 16#42#)) = "AB");
		pragma Assert (System.Native_Encoding.Strings.Decode (D, (16#82#, 16#a0#)) = Japanease_A);
		null;
	end;
	declare
		WD : System.Native_Encoding.Wide_Strings.Decoder :=
			System.Native_Encoding.Wide_Strings.From (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Wide_Strings.Decode (WD, (16#41#, 16#42#)) = "AB");
		null;
	end;
	declare
		WWD : System.Native_Encoding.Wide_Wide_Strings.Decoder :=
			System.Native_Encoding.Wide_Wide_Strings.From (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Wide_Wide_Strings.Decode (WWD, (16#41#, 16#42#)) = "AB");
		null;
	end;
	-- encoding
	declare
		E : System.Native_Encoding.Strings.Encoder :=
			System.Native_Encoding.Strings.To (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Strings.Encode (E, "") = (1 .. 0 => <>));
		pragma Assert (System.Native_Encoding.Strings.Encode (E, "A") = (1 => 16#41#));
		pragma Assert (System.Native_Encoding.Strings.Encode (E, "AB") = (16#41#, 16#42#));
		pragma Assert (System.Native_Encoding.Strings.Encode (E, Japanease_A) = (16#82#, 16#a0#));
		null;
	end;
	declare
		WE : System.Native_Encoding.Wide_Strings.Encoder :=
			System.Native_Encoding.Wide_Strings.To (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Wide_Strings.Encode (WE, "AB") = (16#41#, 16#42#));
		null;
	end;
	declare
		WWE : System.Native_Encoding.Wide_Wide_Strings.Encoder :=
			System.Native_Encoding.Wide_Wide_Strings.To (System.Native_Encoding.Names.Windows_31J);
	begin
		pragma Assert (System.Native_Encoding.Wide_Wide_Strings.Encode (WWE, "AB") = (16#41#, 16#42#));
		null;
	end;
	-- reading
	declare
		Buffer : Ada.Streams.Buffer_Storage_IO.Buffer;
		E : aliased System.Native_Encoding.Encoding_Streams.Encoding :=
			System.Native_Encoding.Encoding_Streams.Open (
				System.Native_Encoding.Names.UTF_8,
				System.Native_Encoding.Names.Windows_31J,
				Ada.Streams.Buffer_Storage_IO.Stream (Buffer));
		S : String (1 .. 3);
	begin
		Ada.Streams.Write (
			Ada.Streams.Buffer_Storage_IO.Stream (Buffer).all,
			(16#82#, 16#a0#));
		Ada.Streams.Set_Index (
			Ada.Streams.Seekable_Stream_Type'Class (Ada.Streams.Buffer_Storage_IO.Stream (Buffer).all),
			1);
		String'Read (
			System.Native_Encoding.Encoding_Streams.Stream (E),
			S);
		pragma Assert (S = Japanease_A);
	end;
	-- writing
	declare
		Buffer : Ada.Streams.Buffer_Storage_IO.Buffer;
		E : aliased System.Native_Encoding.Encoding_Streams.Encoding :=
			System.Native_Encoding.Encoding_Streams.Open (
				System.Native_Encoding.Names.Windows_31J,
				System.Native_Encoding.Names.UTF_8,
				Ada.Streams.Buffer_Storage_IO.Stream (Buffer));
		S : String (1 .. 3);
	begin
		Ada.Streams.Write (
			System.Native_Encoding.Encoding_Streams.Stream (E).all,
			(16#82#, 16#a0#));
		Ada.Streams.Set_Index (
			Ada.Streams.Seekable_Stream_Type'Class (Ada.Streams.Buffer_Storage_IO.Stream (Buffer).all),
			1);
		pragma Assert (Ada.Streams.Stream_Element_Count'(Ada.Streams.Buffer_Storage_IO.Size (Buffer)) = 3);
		String'Read (
			Ada.Streams.Buffer_Storage_IO.Stream (Buffer),
			S);
		pragma Assert (S = Japanease_A);
	end;
	pragma Debug (Ada.Debug.Put ("OK"));
end nls;
