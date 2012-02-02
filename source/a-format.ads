pragma License (Unrestricted);
--  extended unit
package Ada.Formatting is
   --  There are generic formatting functions more powerful than
   --    Ada.Text_IO.*_IO.
   pragma Pure;

   type Form_Type is (Simple, Ada);

   type Sign_Marks is array (-1 .. 1) of Character;
   type Unsign_Marks is array (0 .. 1) of Character;

   None : constant Character := Character'Val (0);

   Plus_Sign_Marks : constant Sign_Marks := ('-', '+', '+');
   Spacing_Sign_Marks : constant Sign_Marks := ('-', ' ', ' ');
   Triming_Sign_Marks : constant Sign_Marks := ('-', None, None);
   Spacing_Unsign_Marks : constant Unsign_Marks := (' ', ' ');
   Triming_Unsign_Marks : constant Unsign_Marks := (None, None);

   subtype Number_Base is Integer range 2 .. 16; -- same as Text_IO.Number_Base

   type Casing_Type is (Upper, Lower);
   --  same as System.Formating.Casing_Type

   generic
      type T is range <>;
      Form : Form_Type := Ada;
      Signs : Sign_Marks := Spacing_Sign_Marks;
      Base : Number_Base := 10;
      Casing : Casing_Type := Upper;
      Width : Positive := 1;
      Padding : Character := '0';
   function Integer_Image (Item : T) return String;

   generic
      type T is mod <>;
      Form : Form_Type := Ada;
      Signs : Unsign_Marks := Spacing_Unsign_Marks;
      Base : Number_Base := 10;
      Casing : Casing_Type := Upper;
      Width : Positive := 1;
      Padding : Character := '0';
   function Modular_Image (Item : T) return String;

   generic
      type T is digits <>;
      Form : Form_Type := Ada;
      Signs : Sign_Marks := Spacing_Sign_Marks;
      Base : Number_Base := 10;
      Casing : Casing_Type := Upper;
      Fore_Width : Positive := 1;
      Fore_Padding : Character := '0';
      Aft_Width : Positive := T'Digits - 1;
      Exponent_Mark : Character := 'E';
      Exponent_Signs : Sign_Marks := Plus_Sign_Marks;
      Exponent_Width : Positive := 2;
      Exponent_Padding : Character := '0';
      NaN : String := "NAN";
      Infinity : String := "INF";
   function Float_Image (Item : T) return String;

   generic
      type T is delta <>;
      Form : Form_Type := Ada;
      Exponent : Boolean := False;
      Signs : Sign_Marks := Spacing_Sign_Marks;
      Base : Number_Base := 10;
      Casing : Casing_Type := Upper;
      Fore_Width : Positive := 1;
      Fore_Padding : Character := '0';
      Aft_Width : Positive := T'Aft;
      Exponent_Mark : Character := 'E';
      Exponent_Signs : Sign_Marks := Plus_Sign_Marks;
      Exponent_Width : Positive := 2;
      Exponent_Padding : Character := '0';
   function Fixed_Image (Item : T) return String;

   generic
      type T is delta <> digits <>;
      Form : Form_Type := Ada;
      pragma Unreferenced (Form); -- 10-based only
      Exponent : Boolean := False;
      Signs : Sign_Marks := Spacing_Sign_Marks;
      Fore_Width : Positive := 1;
      Fore_Padding : Character := '0';
      Aft_Width : Positive := T'Aft;
      Exponent_Mark : Character := 'E';
      Exponent_Signs : Sign_Marks := Plus_Sign_Marks;
      Exponent_Width : Positive := 2;
      Exponent_Padding : Character := '0';
   function Decimal_Image (Item : T) return String;

end Ada.Formatting;
