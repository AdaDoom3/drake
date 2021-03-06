pragma License (Unrestricted);
--  implementation unit for Ada.Directories
with Ada.IO_Exceptions;
with Ada.Streams;
with System.Native_Time;
with C.dirent;
with C.sys.stat;
with C.sys.types;
private package Ada.Directory_Searching is
   pragma Preelaborate;

   subtype Directory_Entry_Type is C.dirent.struct_dirent64;

   type Directory_Entry_Additional_Type is record
      Filled : Boolean;
      Information : aliased C.sys.stat.struct_stat64;
   end record;
   pragma Suppress_Initialization (Directory_Entry_Additional_Type);

   --  same as Directories.File_Kind
   type File_Kind is (Directory, Ordinary_File, Special_File);
   pragma Discard_Names (File_Kind);
   --  same as Directories.Filter_Type
   type Filter_Type is array (File_Kind) of Boolean;
   pragma Pack (Filter_Type);
   pragma Suppress_Initialization (Filter_Type);

   subtype Handle_Type is C.dirent.DIR_ptr;

   Null_Handle : constant Handle_Type := null;

   type Search_Type is record
      Handle : C.dirent.DIR_ptr;
      Pattern : C.char_ptr;
      Filter : Filter_Type;
   end record;
   pragma Suppress_Initialization (Search_Type);

   procedure Start_Search (
      Search : in out Search_Type;
      Directory : String;
      Pattern : String;
      Filter : Filter_Type;
      Directory_Entry : not null access Directory_Entry_Type;
      Has_Next_Entry : out Boolean);

   procedure End_Search (Search : in out Search_Type);

   procedure Get_Next_Entry (
      Search : in out Search_Type;
      Directory_Entry : not null access Directory_Entry_Type;
      Has_Next_Entry : out Boolean);

   function Simple_Name (Directory_Entry : Directory_Entry_Type)
      return String;

   function Kind (Directory_Entry : Directory_Entry_Type)
      return File_Kind;

   function Size (
      Directory : String;
      Directory_Entry : Directory_Entry_Type;
      Additional : not null access Directory_Entry_Additional_Type)
      return Streams.Stream_Element_Count;

   function Modification_Time (
      Directory : String;
      Directory_Entry : Directory_Entry_Type;
      Additional : not null access Directory_Entry_Additional_Type)
      return System.Native_Time.Native_Time;

   Name_Error : exception
      renames IO_Exceptions.Name_Error;
   Use_Error : exception
      renames IO_Exceptions.Use_Error;

   --  for Ada.Directories

   function To_File_Kind (mode : C.sys.types.mode_t) return File_Kind;

   procedure Get_Information (
      Directory : String;
      Directory_Entry : Directory_Entry_Type;
      Information : not null access C.sys.stat.struct_stat64);

end Ada.Directory_Searching;
