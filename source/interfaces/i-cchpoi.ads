pragma License (Unrestricted);
--  extended package
with Interfaces.C.Pointers;
package Interfaces.C.Char_Pointers is new Interfaces.C.Pointers (
   Index => size_t,
   Element => char,
   Element_Array => char_array,
   Default_Terminator => char'Val (0));
pragma Pure (Interfaces.C.Char_Pointers);
