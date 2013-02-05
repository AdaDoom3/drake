with Ada.Exceptions;
with Ada.Permissions.Inside;
with System.Zero_Terminated_Strings;
package body Ada.Directories.Volumes is
   use type File_Size;
   use type C.signed_int;

   function Where (Name : String) return File_System is
      Z_Name : constant String := Name & Character'Val (0);
      C_Name : C.char_array (C.size_t);
      for C_Name'Address use Z_Name'Address;
   begin
      return Result : File_System do
         if statfs (C_Name (0)'Access, Result'Unrestricted_Access) < 0 then
            Exceptions.Raise_Exception_From_Here (Name_Error'Identity);
         end if;
      end return;
   end Where;

   function Size (FS : File_System) return File_Size is
   begin
      return File_Size (FS.f_blocks) * File_Size (FS.f_bsize);
   end Size;

   function Free_Space (FS : File_System) return File_Size is
   begin
      return File_Size (FS.f_bfree) * File_Size (FS.f_bsize);
   end Free_Space;

   function Owner (FS : File_System) return String is
   begin
      return Permissions.Inside.User_Name (FS.f_owner);
   end Owner;

   function Format_Name (FS : File_System) return String is
   begin
      return System.Zero_Terminated_Strings.Value (FS.f_fstypename'Address);
   end Format_Name;

   function Directory (FS : File_System) return String is
   begin
      return System.Zero_Terminated_Strings.Value (FS.f_mntonname'Address);
   end Directory;

   function Device (FS : File_System) return String is
   begin
      return System.Zero_Terminated_Strings.Value (FS.f_mntfromname'Address);
   end Device;

end Ada.Directories.Volumes;
