pragma License (Unrestricted);
--  implementation package required by compiler
package System.Bit_Ops is
   pragma Pure;

   --  required for "=" packed boolean array by compiler (s-bitop.ads)
   function Bit_Eq (
      Left : Address;
      Llen : Natural;
      Right : Address;
      Rlen : Natural)
      return Boolean;
   pragma Pure_Function (Bit_Eq);

   --  required by compiler ??? (s-bitop.ads)
--  procedure Bit_Not (
--    Opnd : Address;
--    Len : Natural;
--    Result : Address);
--  procedure Bit_And (
--    Left : Address;
--    Llen : Natural;
--    Right : Address;
--    Rlen : Natural;
--    Result : Address);
--  procedure Bit_Or (
--    Left : Address;
--    Llen : Natural;
--    Right : Address;
--    Rlen : Natural;
--    Result : Address);
--  procedure Bit_Xor (
--    Left : Address;
--    Llen : Natural;
--    Right : Address;
--    Rlen : Natural;
--    Result : Address);

end System.Bit_Ops;
