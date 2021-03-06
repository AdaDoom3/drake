with Ada.Exception_Identification.From_Here;
with Ada.IO_Exceptions;
with C.fcntl;
with C.sys.types;
with C.unistd;
procedure Ada.Numerics.Initiator (
   Item : System.Address;
   Size : System.Storage_Elements.Storage_Count)
is
   pragma Suppress (All_Checks);
   use Exception_Identification.From_Here;
   use type C.char_array;
   use type C.signed_int; -- ssize_t is signed int or signed long
   use type C.signed_long;
   use type C.size_t;
   Random_File_Name : constant C.char_array := "/dev/random" & C.char'Val (0);
   F : C.signed_int;
   Read_Size : C.sys.types.ssize_t;
   Closed : C.signed_int;
begin
   F := C.fcntl.open (
      Random_File_Name (0)'Access,
      C.fcntl.O_RDONLY);
   if F = -1 then
      Raise_Exception (IO_Exceptions.Use_Error'Identity);
   end if;
   Read_Size := C.unistd.read (F, C.void_ptr (Item), C.size_t (Size));
   Closed := C.unistd.close (F);
   if Read_Size /= C.sys.types.ssize_t (Size) or else Closed = -1 then
      Raise_Exception (IO_Exceptions.Use_Error'Identity);
   end if;
end Ada.Numerics.Initiator;
