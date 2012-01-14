pragma License (Unrestricted);
with Ada.IO_Exceptions;
with Ada.IO_Modes;
private with Ada.Finalization;
limited private with Ada.Streams.Stream_IO.Inside;
package Ada.Streams.Stream_IO is
   pragma Preelaborate; -- AI12-0010-1

   type Stream_Access is access all Root_Stream_Type'Class;

   type File_Type is limited private;

--  type File_Mode is (In_File, Out_File, Append_File);
   type File_Mode is new IO_Modes.File_Mode; -- for conversion

   --  modified
--  type Count is range 0 .. implementation-defined;
   subtype Count is Stream_Element_Count;
   subtype Positive_Count is Count range 1 .. Count'Last;
   --  Index into file, in stream elements

   procedure Create (
      File : in out File_Type;
      Mode : File_Mode := Out_File;
      Name : String := "";
      Form : String := "");
   --  extended
   function Create (
      Mode : File_Mode := Out_File;
      Name : String := "";
      Form : String := "")
      return File_Type;

   procedure Open (
      File : in out File_Type;
      Mode : File_Mode;
      Name : String;
      Form : String := "");
   --  extended
   function Open (
      Mode : File_Mode;
      Name : String;
      Form : String := "")
      return File_Type;

   procedure Close (File : in out File_Type);
   procedure Delete (File : in out File_Type);
   procedure Reset (File : in out File_Type; Mode : File_Mode);
   procedure Reset (File : in out File_Type);

   function Mode (File : File_Type) return File_Mode;
   pragma Inline (Mode);
   function Name (File : File_Type) return String;
   pragma Inline (Name);
   function Form (File : File_Type) return String;
   pragma Inline (Form);

   function Is_Open (File : File_Type) return Boolean;
   pragma Inline (Is_Open);
   function End_Of_File (File : File_Type) return Boolean;
   pragma Inline (End_Of_File);

   function Stream (File : File_Type) return Stream_Access;
   pragma Inline (Stream);
   --  Return stream access for use with T'Input and T'Output

   --  Read array of stream elements from file
   procedure Read (
      File : File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset;
      From : Positive_Count);
   procedure Read (
      File : File_Type;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset);

   --  Write array of stream elements into file
   procedure Write (
      File : File_Type;
      Item : Stream_Element_Array;
      To : Positive_Count);
   procedure Write (
      File : File_Type;
      Item : Stream_Element_Array);

   --  Operations on position within file

   procedure Set_Index (File : File_Type; To : Positive_Count);

   function Index (File : File_Type) return Positive_Count;
   pragma Inline (Index);
   function Size (File : File_Type) return Count;
   pragma Inline (Size);

   procedure Set_Mode (File : in out File_Type; Mode : File_Mode);

   procedure Flush (File : File_Type);

   --  exceptions

   Status_Error : exception
      renames IO_Exceptions.Status_Error;
   Mode_Error : exception
      renames IO_Exceptions.Mode_Error;
   Name_Error : exception
      renames IO_Exceptions.Name_Error;
   Use_Error : exception
      renames IO_Exceptions.Use_Error;
   Device_Error : exception
      renames IO_Exceptions.Device_Error;
   End_Error : exception
      renames IO_Exceptions.End_Error;
   Data_Error : exception
      renames IO_Exceptions.Data_Error;

private

   type File_Type is
      limited new Finalization.Limited_Controlled with
   record
      Stream : access Inside.Stream_Type;
   end record;

   overriding procedure Finalize (Object : in out File_Type);

end Ada.Streams.Stream_IO;
