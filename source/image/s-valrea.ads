pragma License (Unrestricted);
--  implementation package required by compiler
package System.Val_Real is
   pragma Pure;

   --  required for Float'Value by compiler (s-valrea.ads)
   function Value_Real (Str : String) return Long_Long_Float;

   --  helper
   procedure Get_Float_Literal (
      S : String;
      Last : out Natural;
      Result : out Long_Long_Float;
      Error : out Boolean);

end System.Val_Real;
