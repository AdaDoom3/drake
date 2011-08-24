pragma License (Unrestricted);
--  implementation package
package System.UTF_Conversions is
   pragma Pure;

   --  UCS-4 defined 31 bit.
   type UCS_4 is mod 16#80000000#;

   function Shift_Left (Left : UCS_4; Right : Natural) return UCS_4;
   pragma Import (Intrinsic, Shift_Left);

   UTF_8_Max_Length : constant := 6;

   procedure To_UTF_8 (
      Code : UCS_4;
      Result : out String;
      Last : out Natural;
      Error : out Boolean);
   procedure From_UTF_8 (
      Data : String;
      Last : out Natural;
      Result : out UCS_4;
      Error : out Boolean);
   procedure From_UTF_8_Reverse (
      Data : String;
      First : out Positive;
      Result : out UCS_4;
      Error : out Boolean);
   procedure UTF_8_Sequence (
      Leading : Character;
      Result : out Positive;
      Error : out Boolean);

   UTF_16_Max_Length : constant := 2;

   procedure To_UTF_16 (
      Code : UCS_4;
      Result : out Wide_String;
      Last : out Natural;
      Error : out Boolean);
   procedure From_UTF_16 (
      Data : Wide_String;
      Last : out Natural;
      Result : out UCS_4;
      Error : out Boolean);
   procedure From_UTF_16_Reverse (
      Data : Wide_String;
      First : out Positive;
      Result : out UCS_4;
      Error : out Boolean);
   procedure UTF_16_Sequence (
      Leading : Wide_Character;
      Result : out Positive;
      Error : out Boolean);

   procedure To_UTF_32 (
      Code : UCS_4;
      Result : out Wide_Wide_String;
      Last : out Natural;
      Error : out Boolean);
   procedure From_UTF_32 (
      Data : Wide_Wide_String;
      Last : out Natural;
      Result : out UCS_4;
      Error : out Boolean);
   procedure From_UTF_32_Reverse (
      Data : Wide_Wide_String;
      First : out Positive;
      Result : out UCS_4;
      Error : out Boolean);
   procedure UTF_32_Sequence (
      Leading : Wide_Wide_Character;
      Result : out Positive;
      Error : out Boolean);

   generic
      type Source_Element_Type is (<>);
      type Source_Type is array (Positive range <>) of Source_Element_Type;
      type Target_Element_Type is (<>);
      type Target_Type is array (Positive range <>) of Target_Element_Type;
      with procedure From_UTF (
         Data : Source_Type;
         Last : out Natural;
         Result : out UCS_4;
         Error : out Boolean);
      with procedure To_UTF (
         Code : UCS_4;
         Result : out Target_Type;
         Last : out Natural;
         Error : out Boolean);
   procedure Convert_Procedure (
      Source : Source_Type;
      Result : out Target_Type;
      Last : out Natural;
      Substitute : Target_Element_Type := Target_Element_Type'Val (16#20#));

   generic
      type Source_Element_Type is (<>);
      type Source_Type is array (Positive range <>) of Source_Element_Type;
      type Target_Element_Type is (<>);
      type Target_Type is array (Positive range <>) of Target_Element_Type;
      Expanding : Positive;
      with procedure Convert_Procedure (
         Source : Source_Type;
         Result : out Target_Type;
         Last : out Natural;
         Substitute : Target_Element_Type);
   function Convert_Function (
      Source : Source_Type;
      Substitute : Target_Element_Type := Target_Element_Type'Val (16#20#))
      return Target_Type;

end System.UTF_Conversions;
