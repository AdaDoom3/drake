pragma License (Unrestricted);
--  implementation package
procedure System.Formatting.Float_Image (
   To : out String; -- To'Length >= Long_Long_Float'Width + 4 (16##)
   Last : out Natural;
   Item : Long_Long_Float;
   Minus_Sign : Character := '-';
   Zero_Sign : Character := ' ';
   Plus_Sign : Character := ' ';
   Base : Number_Base := 10;
   Base_Form : Boolean := False;
   Casing : Casing_Type := Upper;
   Fore_Width : Positive := 1;
   Fore_Padding : Character := '0';
   Aft_Width : Positive;
   Exponent_Mark : Character := 'E';
   Exponent_Minus_Sign : Character := '-';
   Exponent_Zero_Sign : Character := '+';
   Exponent_Plus_Sign : Character := '+';
   Exponent_Width : Positive := 2;
   Exponent_Padding : Character := '0';
   NaN : String := "NAN";
   Infinity : String := "INF");
pragma Pure (System.Formatting.Float_Image);
