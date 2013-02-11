with Ada.Exceptions;
with System.Zero_Terminated_Strings;
with C.stdlib;
with C.unistd;
package body Ada.Directories.Temporary is
   use type C.char_array;
   use type C.char_ptr;
   use type C.signed_int;

   Temp_Variable : constant C.char_array := "TMPDIR" & C.char'Val (0);
   Temp_Template : constant String := "ADAXXXXXX";

   --  implementation

   function Temporary_Directory return String is
      Temp_Dir : C.char_ptr;
   begin
      Temp_Dir := C.stdlib.getenv (
         Temp_Variable (Temp_Variable'First)'Access);
      if Temp_Dir = null then
         return Current_Directory;
      else
         return System.Zero_Terminated_Strings.Value (Temp_Dir.all'Address);
      end if;
   end Temporary_Directory;

   procedure Set_Temporary_Directory (Name : String) is
      Last : constant Integer := Name'Length;
      Z_Name : String (1 .. Last + 1);
      C_Name : C.char_array (C.size_t);
      for C_Name'Address use Z_Name'Address;
   begin
      Z_Name (1 .. Last) := Name;
      Z_Name (Last + 1) := Character'Val (0);
      if C.stdlib.setenv (
         Temp_Variable (Temp_Variable'First)'Access,
         C_Name (C_Name'First)'Access,
         1) /= 0
      then
         Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
      end if;
   end Set_Temporary_Directory;

   function Create_Temporary_File (
      Directory : String := Temporary_Directory) return String
   is
      Template : String (1 .. Directory'Length + Temp_Template'Length + 2);
      Last : Integer := Directory'Length;
   begin
      Template (1 .. Last) := Directory;
      Hierarchical_File_Names.Include_Trailing_Path_Delimiter (Template, Last);
      Template (Last + 1 .. Last + Temp_Template'Length) := Temp_Template;
      Last := Last + Temp_Template'Length;
      Template (Last + 1) := Character'Val (0);
      declare
         C_Template : aliased C.char_array (C.size_t);
         for C_Template'Address use Template'Address;
         Handle : C.signed_int;
         Dummy : C.signed_int;
         pragma Unreferenced (Dummy);
      begin
         declare -- mkstemp where
            use C.stdlib; -- Linux, POSIX.1-2008
            use C.unistd; -- Darwin, FreeBSD
         begin
            Handle := mkstemp (C_Template (0)'Access);
         end;
         if Handle < 0 then
            Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
         end if;
         Dummy := C.unistd.close (Handle);
      end;
      return Template (1 .. Last);
   end Create_Temporary_File;

   function Create_Temporary_Directory (
      Directory : String := Temporary_Directory) return String
   is
      Template : String (1 .. Directory'Length + Temp_Template'Length + 2);
      Last : Integer := Directory'Length;
   begin
      Template (1 .. Last) := Directory;
      Hierarchical_File_Names.Include_Trailing_Path_Delimiter (Template, Last);
      Template (Last + 1 .. Last + Temp_Template'Length) := Temp_Template;
      Last := Last + Temp_Template'Length;
      Template (Last + 1) := Character'Val (0);
      declare
         C_Template : aliased C.char_array (C.size_t);
         for C_Template'Address use Template'Address;
         R : C.char_ptr;
      begin
         declare -- mkdtemp where
            use C.stdlib; -- Linux, POSIX.1-2008
            use C.unistd; -- Darwin, FreeBSD
         begin
            R := mkdtemp (C_Template (0)'Access);
         end;
         if R = null then
            Exceptions.Raise_Exception_From_Here (Use_Error'Identity);
         end if;
      end;
      return Template (1 .. Last);
   end Create_Temporary_Directory;

end Ada.Directories.Temporary;
