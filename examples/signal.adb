-- stack trace must be shown with gnatbind -E
with Ada;
with Unchecked_Conversion; -- renamed ver
with System.Formatting;
with System.Machine_Code;
with System.Storage_Elements;
with Interfaces;
procedure signal is
	use type Interfaces.Unsigned_16;
	CW : aliased Interfaces.Unsigned_16 := 0;
	type T is access Integer;
	function Cast is
		new Unchecked_Conversion (System.Storage_Elements.Integer_Address, T);
	A : T := Cast (12345678);
	X : Integer := 10;
	Y : Integer := 20;
	-- Z : Long_Float;
	function sqrt (d : Long_Float) return Long_Float;
	pragma Import (C, sqrt);
	procedure Deep is
		pragma Suppress (All_Checks);
	begin
		-- A.all := 0; -- may cause SIGSEGV (segmentation fault)
		X := X / Y; -- may cause SIGFPE (floating point exception)

		-- Z := sqrt (-1.0); -- OSX success ???
	end Deep;
begin
	System.Machine_Code.Asm ("fstcw (%0)",
		Inputs => System.Address'Asm_Input ("r", CW'Address),
		Volatile => True);
	CW := CW and not 16#001f#;
	System.Machine_Code.Asm ("fldcw %0",
		Inputs => Interfaces.Unsigned_16'Asm_Input ("m", CW),
		Volatile => True);
	CW := 0;
	System.Machine_Code.Asm ("fstcw (%0)",
		Inputs => System.Address'Asm_Input ("r", CW'Address),
		Volatile => True);
	declare
		S : String (1 .. 4);
		Last : Natural;
		Error : Boolean;
	begin
		System.Formatting.Image (
			System.Formatting.Unsigned (CW),
			S,
			Last,
			16,
			Width => 4,
			Error => Error);
		Ada.Debug.Put (S);
	end;
	Y := 0;
	Ada.Debug.Put ("CONSTRAINT_ERROR is right.");
	Deep;
end signal;
