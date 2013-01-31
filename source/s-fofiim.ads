pragma License (Unrestricted);
--  implementation unit
procedure System.Formatting.Fixed_Image (
   To : out String; -- To'Length >= T'Fore + T'Aft + 5 (16#.#)
   Last : out Natural;
   Item : Long_Long_Float;
   Minus_Sign : Character := '-';
   Zero_Sign : Character := ' ';
   Plus_Sign : Character := ' ';
   Base : Number_Base := 10;
   Base_Form : Boolean := False;
   Set : Type_Set := Upper_Case;
   Fore_Width : Positive := 1;
   Fore_Padding : Character := '0';
   Aft_Width : Positive);
pragma Pure (System.Formatting.Fixed_Image);
