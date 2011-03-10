with Ada.Text_IO.Inside.Formatting;
with System.Formatting.Decimal_Image;
with System.Formatting.Float_Image;
with System.Val_Real;
package body Ada.Text_IO.Decimal_IO is
   pragma Suppress (All_Checks);

   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Aft : Field;
      Exp : Field);
   procedure Put_To_Field (
      To : out String;
      Last : out Natural;
      Item : Num;
      Aft : Field;
      Exp : Field) is
   begin
      if Exp /= 0 then
         --  decimal version should be implemented...
         System.Formatting.Float_Image (
            To,
            Last,
            Long_Long_Float (Item),
            Zero_Sign => Character'Val (0),
            Plus_Sign => Character'Val (0),
            Aft_Width => Aft,
            Exponent_Width => Exp - 1);
      else
         System.Formatting.Decimal_Image (
            To,
            Last,
            Long_Long_Integer'Integer_Value (Item),
            Num'Scale,
            Zero_Sign => Character'Val (0),
            Plus_Sign => Character'Val (0),
            Aft_Width => Aft);
      end if;
   end Put_To_Field;

   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive);
   procedure Get_From_Field (
      From : String;
      Item : out Num;
      Last : out Positive)
   is
      Result : Long_Long_Float;
   begin
      --  decimal version should be implemented...
      System.Val_Real.Get_Float_Literal (
         From,
         Last,
         Result);
      if Result < Long_Long_Float (Num'First)
         or else Result > Long_Long_Float (Num'Last)
      then
         raise Data_Error;
      end if;
      Item := Num (Result);
   exception
      when Constraint_Error =>
         raise Data_Error;
   end Get_From_Field;

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
               Inside.Formatting.Get_Numeric_Literal (File, Real => True);
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
      Fore : Field := Default_Fore;
      Aft : Field := Default_Aft;
      Exp : Field := Default_Exp)
   is
      S : String (
         1 ..
         Integer'Max (Num'Width, Long_Long_Float'Width) + Aft + Exp);
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Aft, Exp);
      Inside.Formatting.Tail (File, S (1 .. Last), Fore + Aft + Exp + 1);
   end Put;

   procedure Put (
      Item : Num;
      Fore : Field := Default_Fore;
      Aft : Field := Default_Aft;
      Exp : Field := Default_Exp) is
   begin
      Put (Current_Output.all, Item, Fore, Aft, Exp);
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
      Aft : Field := Default_Aft;
      Exp : Field := Default_Exp)
   is
      S : String (
         1 ..
         Integer'Max (Num'Width, Long_Long_Float'Width) + Aft + Exp);
      Last : Natural;
   begin
      Put_To_Field (S, Last, Item, Aft, Exp);
      Inside.Formatting.Tail (To, S (1 .. Last));
   end Put;

end Ada.Text_IO.Decimal_IO;