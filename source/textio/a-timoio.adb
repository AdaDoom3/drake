with Ada.Text_IO.Inside.Formatting;
with System.Formatting;
with System.Val_LLU;
with System.Val_Uns;
package body Ada.Text_IO.Modular_IO is
   use type System.Formatting.Longest_Unsigned;
   use type System.Formatting.Unsigned;

   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Base : Number_Base;
      Padding : Character;
      Padding_Width : Field);
   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Base : Number_Base;
      Padding : Character;
      Padding_Width : Field) is
   begin
      if Num'Size > System.Formatting.Unsigned'Size then
         Inside.Formatting.Modular_Image (
            To,
            Last,
            System.Formatting.Longest_Unsigned (Item),
            Base,
            Padding,
            Padding_Width);
      else
         Inside.Formatting.Modular_Image (
            To,
            Last,
            System.Formatting.Unsigned (Item),
            Base,
            Padding,
            Padding_Width);
      end if;
   end Put_To_Field;

   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive);
   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive) is
   begin
      if Num'Size > System.Formatting.Unsigned'Size then
         declare
            Result : System.Formatting.Longest_Unsigned;
            Error : Boolean;
         begin
            System.Val_LLU.Get_Longest_Unsigned_Literal (
               From,
               Last,
               Result,
               Error => Error);
            if Error
               or else Result > System.Formatting.Longest_Unsigned (Num'Last)
            then
               raise Data_Error;
            end if;
            Item := Num (Result);
         end;
      else
         declare
            Result : System.Formatting.Unsigned;
            Error : Boolean;
         begin
            System.Val_Uns.Get_Unsigned_Literal (
               From,
               Last,
               Result,
               Error => Error);
            if Error
               or else Result > System.Formatting.Unsigned'Mod (Num'Last)
            then
               raise Data_Error;
            end if;
            Item := Num (Result);
         end;
      end if;
   end Get_From_Field;

   --  implementation

   procedure Get (
      File : File_Type;
      Item : out Num;
      Width : Field := 0) is
   begin
      if Width /= 0 then
         declare
            S : String (1 .. Width);
            Last_1 : Natural;
            Last_2 : Natural;
         begin
            Inside.Formatting.Get_Field (File, S, Last_1);
            Get_From_Field (S (1 .. Last_1), Item, Last_2);
            if Last_2 /= Last_1 then
               raise Data_Error;
            end if;
         end;
      else
         declare
            S : constant String :=
               Inside.Formatting.Get_Numeric_Literal (File, Real => False);
            Last : Natural;
         begin
            Get_From_Field (S, Item, Last);
            if Last /= S'Last then
               raise Data_Error;
            end if;
         end;
      end if;
   end Get;

   procedure Get (
      Item : out Num;
      Width : Field := 0) is
   begin
      Get (Current_Input.all, Item, Width);
   end Get;

   procedure Put (
      File : File_Type;
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding)
   is
      S : String (1 .. 4 + Num'Width + Width); -- "16##"
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Base, Padding, Width);
      Inside.Formatting.Tail (File, S (1 .. Last), Width);
   end Put;

   procedure Put (
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding) is
   begin
      Put (Current_Output.all, Item, Width, Base, Padding);
   end Put;

   procedure Get (
      From : String;
      Item : out Num;
      Last : out Positive) is
   begin
      Inside.Formatting.Get_Tail (From, First => Last);
      Get_From_Field (From (Last .. From'Last), Item, Last);
   end Get;

   procedure Put (
      To : out String;
      Item : Num;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding)
   is
      S : String (1 .. To'Length);
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Base, Padding, To'Length);
      Inside.Formatting.Tail (To, S (1 .. Last));
   end Put;

end Ada.Text_IO.Modular_IO;
