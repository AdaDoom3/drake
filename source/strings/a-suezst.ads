pragma License (Unrestricted);
--  Ada 2012
with Ada.Strings.UTF_Encoding.Conversions;
package Ada.Strings.UTF_Encoding.Wide_Wide_Strings is
   pragma Pure;

   --  Encoding / decoding between Wide_Wide_String
   --  and various encoding schemes
   function Encode (
      Item : Wide_Wide_String;
      Output_Scheme : Encoding_Scheme;
      Output_BOM : Boolean := False)
      return UTF_String
      renames Conversions.Convert;

   function Encode (
      Item : Wide_Wide_String;
      Output_BOM : Boolean := False)
      return UTF_8_String
      renames Conversions.Convert;

   function Encode (
      Item : Wide_Wide_String;
      Output_BOM : Boolean := False)
      return UTF_16_Wide_String
      renames Conversions.Convert;

   function Encode (
      Item : Wide_Wide_String;
      Output_BOM : Boolean := False)
      return UTF_32_Wide_Wide_String;

   function Decode (
      Item : UTF_String;
      Input_Scheme : Encoding_Scheme)
      return Wide_Wide_String;

   function Decode (Item : UTF_8_String) return Wide_Wide_String;

   function Decode (Item : UTF_16_Wide_String) return Wide_Wide_String;

   --  extended
   function Decode (Item : UTF_32_Wide_Wide_String) return Wide_Wide_String;

end Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
