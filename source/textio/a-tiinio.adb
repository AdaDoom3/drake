with Ada.Text_IO.Inside.Formatting;
with System.Val_Int;
with System.Val_LLI;
package body Ada.Text_IO.Integer_IO is

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
      if Num'Size > Integer'Size then
         Inside.Formatting.Integer_Image (
            To,
            Last,
            Long_Long_Integer (Item),
            Base,
            Padding,
            Padding_Width);
      else
         Inside.Formatting.Integer_Image (
            To,
            Last,
            Integer (Item),
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
      if Num'Size > Integer'Size then
         declare
            Result : Long_Long_Integer;
            Error : Boolean;
         begin
            System.Val_LLI.Get_Long_Long_Integer_Literal (
               From,
               Last,
               Result,
               Error => Error);
            if Error
               or else Result not in
                  Long_Long_Integer (Num'First) ..
                  Long_Long_Integer (Num'Last)
            then
               raise Data_Error;
            end if;
            Item := Num (Result);
         end;
      else
         declare
            Result : Integer;
            Error : Boolean;
         begin
            System.Val_Int.Get_Integer_Literal (
               From,
               Last,
               Result,
               Error => Error);
            if Error
               or else Result not in
                  Integer (Num'First) ..
                  Integer (Num'Last)
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

   procedure Get (
      File : not null File_Access;
      Item : out Num;
      Width : Field := 0) is
   begin
      Get (File.all, Item, Width);
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

   procedure Put (
      File : not null File_Access;
      Item : Num;
      Width : Field := Default_Width;
      Base : Number_Base := Default_Base;
      Padding : Character := Default_Padding) is
   begin
      Put (File.all, Item, Width, Base, Padding);
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

end Ada.Text_IO.Integer_IO;
