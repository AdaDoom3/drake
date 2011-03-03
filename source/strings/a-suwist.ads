pragma License (Unrestricted);
--  extended package
with Ada.Strings.Generic_Unbounded;
with System.Strings.Stream_Ops;
package Ada.Strings.Unbounded_Wide_Strings is new Generic_Unbounded (
   Wide_Character,
   Wide_String,
   System.Strings.Stream_Ops.Wide_String_Read_Blk_IO,
   System.Strings.Stream_Ops.Wide_String_Write_Blk_IO);
pragma Preelaborate (Ada.Strings.Unbounded_Wide_Strings);
