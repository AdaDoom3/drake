pragma License (Unrestricted);
--  extended unit
with Ada.IO_Exceptions;
with Ada.Streams;
private with Ada.Finalization;
private with C.icucore;
package System.Native_Encoding is
   --  Platform-depended text encoding.
   pragma Preelaborate;

   --  encoding identifier

   type Encoding_Id is private;

   function Image (Encoding : Encoding_Id) return String;

   function Default_Substitute (Encoding : Encoding_Id)
      return Ada.Streams.Stream_Element_Array;

   function Min_Size_In_Stream_Elements (Encoding : Encoding_Id)
      return Ada.Streams.Stream_Element_Offset;

   UTF_8 : constant Encoding_Id;
   UTF_16 : constant Encoding_Id;
   UTF_32 : constant Encoding_Id;

   Current_Encoding : constant Encoding_Id;

   --  subsidiary types to converter

   type Subsequence_Status_Type is (
      Finished,
      Success,
      Overflow, -- the output buffer is not large enough
      Illegal_Sequence, -- a input character could not be mapped to the output
      Truncated); -- the input buffer is broken off at a multi-byte character

   type Continuing_Status_Type is
      new Subsequence_Status_Type
         range Success .. Subsequence_Status_Type'Last;
   type Finishing_Status_Type is
      new Subsequence_Status_Type
         range Finished .. Overflow;
   type Status_Type is
      new Subsequence_Status_Type
         range Finished .. Illegal_Sequence;

   type Substituting_Status_Type is
      new Status_Type
         range Finished .. Overflow;

   subtype True_Only is Boolean range True .. True;

   --  converter

   type Converter is limited private;

   function Is_Open (Object : Converter) return Boolean;

   function Min_Size_In_From_Stream_Elements (Object : Converter)
      return Ada.Streams.Stream_Element_Offset;

   function Substitute (Object : Converter)
      return Ada.Streams.Stream_Element_Array;

   procedure Set_Substitute (
      Object : in out Converter;
      Substitute : Ada.Streams.Stream_Element_Array);

   --  convert subsequence
   procedure Convert (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : Boolean;
      Status : out Subsequence_Status_Type);

   procedure Convert (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Status : out Continuing_Status_Type);

   procedure Convert (
      Object : Converter;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : True_Only;
      Status : out Finishing_Status_Type);

   --  convert all character sequence
   procedure Convert (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finished : True_Only;
      Status : out Status_Type);

   --  convert all character sequence with substitute
   procedure Convert (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : True_Only;
      Status : out Substituting_Status_Type);

   --  exceptions

   Name_Error : exception
      renames Ada.IO_Exceptions.Name_Error;
   Status_Error : exception
      renames Ada.IO_Exceptions.Status_Error;
   Use_Error : exception
      renames Ada.IO_Exceptions.Use_Error;

private
   use type Ada.Streams.Stream_Element_Offset;
   use type C.char_array;
   use type C.size_t;

   --  max length of one multi-byte character

   Max_Substitute_Length : constant := 6; -- UTF-8

   --  encoding identifier

   type Encoding_Id is access constant C.char;
   for Encoding_Id'Storage_Size use 0;

   UTF_8_Name : aliased constant C.char_array (0 .. 5) :=
      "UTF-8" & C.char'Val (0);
   UTF_8 : constant Encoding_Id := UTF_8_Name (0)'Access;

   UTF_16_Names : aliased constant
      array (Bit_Order) of aliased C.char_array (0 .. 8) := (
         High_Order_First => "UTF-16BE" & C.char'Val (0),
         Low_Order_First => "UTF-16LE" & C.char'Val (0));
   UTF_16 : constant Encoding_Id := UTF_16_Names (Default_Bit_Order)(0)'Access;

   UTF_32_Names : aliased constant
      array (Bit_Order) of aliased C.char_array (0 .. 8) := (
         High_Order_First => "UTF-32BE" & C.char'Val (0),
         Low_Order_First => "UTF-32LE" & C.char'Val (0));
   UTF_32 : constant Encoding_Id := UTF_32_Names (Default_Bit_Order)(0)'Access;

   Current_Encoding : constant Encoding_Id := UTF_8_Name (0)'Access;
   --  In POSIX, other packages (Ada.Command_Line, Ada.Environment_Variables,
   --    Ada.Text_IO, etc) also assume that system encoding is UTF-8.

   --  converter

   Half_Buffer_Length : constant := 64
      / (C.icucore.UChar'Size / Standard'Storage_Unit);

   subtype Buffer_Type is
      C.icucore.UChar_array (0 .. 2 * Half_Buffer_Length - 1);

   type Non_Controlled_Converter is record
      --  about "From"
      From_uconv : C.icucore.UConverter_ptr;
      --  intermediate
      Buffer : Buffer_Type;
      Buffer_First : aliased C.icucore.UChar_const_ptr;
      Buffer_Limit : aliased C.icucore.UChar_ptr; -- Last + 1
      --  about "To"
      To_uconv : C.icucore.UConverter_ptr;
      Substitute_Length : Ada.Streams.Stream_Element_Offset;
      Substitute : Ada.Streams.Stream_Element_Array (
         1 ..
         Max_Substitute_Length);
   end record;
   pragma Suppress_Initialization (Non_Controlled_Converter);

   package Controlled is

      type Converter is limited private;

      procedure Open (Object : out Converter; From, To : Encoding_Id);

      function Reference (Object : Converter)
         return not null access Non_Controlled_Converter;
      pragma Inline (Reference);

   private

      type Converter is
         limited new Ada.Finalization.Limited_Controlled with
      record
         Data : aliased Non_Controlled_Converter := (
            From_uconv => null,
            To_uconv => null,
            others => <>);
      end record;

      overriding procedure Finalize (Object : in out Converter);

   end Controlled;

   type Converter is new Controlled.Converter;

   procedure Convert_No_Check (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : Boolean;
      Status : out Subsequence_Status_Type);

   procedure Convert_No_Check (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Status : out Continuing_Status_Type);

   procedure Convert_No_Check (
      Object : Converter;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : True_Only;
      Status : out Finishing_Status_Type);

   procedure Convert_No_Check (
      Object : Converter;
      Item : Ada.Streams.Stream_Element_Array;
      Last : out Ada.Streams.Stream_Element_Offset;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Finish : True_Only;
      Status : out Substituting_Status_Type);

   procedure Put_Substitute (
      Object : Converter;
      Out_Item : out Ada.Streams.Stream_Element_Array;
      Out_Last : out Ada.Streams.Stream_Element_Offset;
      Is_Overflow : out Boolean);

end System.Native_Encoding;
