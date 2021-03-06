pragma License (Unrestricted);
--  implementation package required by compiler
package System.Val_WChar is
   pragma Pure;

   --  (s-wchcon.ads)
   type WC_Encoding_Method is range 1 .. 6;

   --  required for Wide_Character'Value by compiler (s-valwch.ads)
   function Value_Wide_Character (Str : String; EM : WC_Encoding_Method)
      return Wide_Character;

   --  required for Wide_Wide_Character'Value by compiler (s-valwch.ads)
   function Value_Wide_Wide_Character (Str : String; EM : WC_Encoding_Method)
      return Wide_Wide_Character;

   --  helper
   procedure Get_Named (
      S : String;
      Value : out Wide_Character;
      Error : out Boolean);

end System.Val_WChar;
