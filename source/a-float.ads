pragma License (Unrestricted);
--  extended package
package Ada.Float is
   pragma Pure;

   generic
      type Float_Type is digits <>;
   function Infinity return Float_Type;

   generic
      type Float_Type is digits <>;
   function NaN return Float_Type;

   generic
      type Float_Type is digits <>;
   function Is_Infinity (X : Float_Type) return Boolean;

   generic
      type Float_Type is digits <>;
   function Is_NaN (X : Float_Type) return Boolean;

   generic
      type Float_Type is digits <>;
   function Is_Negative (X : Float_Type) return Boolean;

   generic
      type Dividend_Type is digits <>;
      type Divisor_Type is digits <>;
      type Quotient_Type is digits <>;
      type Remainder_Type is digits <>;
   procedure Divide (
      Dividend : Dividend_Type;
      Divisor : Divisor_Type;
      Quotient : out Quotient_Type;
      Remainder : out Remainder_Type);

end Ada.Float;
