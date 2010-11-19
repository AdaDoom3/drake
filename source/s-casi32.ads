pragma License (Unrestricted);
--  implementation package required by compiler
package System.Compare_Array_Signed_32 is
   pragma Pure;

   --  required to compare arrays by compiler (s-casi32.ads)
   function Compare_Array_S32 (
      Left : System.Address;
      Right : System.Address;
      Left_Len : Natural;
      Right_Len : Natural)
      return Integer;

end System.Compare_Array_Signed_32;
