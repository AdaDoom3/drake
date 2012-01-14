pragma License (Unrestricted);
--  extended unit
with Ada.Numerics;
package Ada.Float.Elementary_Functions is
   --  There are elementary functions for float-types.
   pragma Pure;

   generic
      type Float_Type is digits <>;
   function Sqrt (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Sqrt);

   generic
      type Float_Type is digits <>;
   function Log (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Log);

   generic
      type Float_Type is digits <>;
   function Exp (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Exp);

   --  "**"
   generic
      type Float_Type is digits <>;
   function Pow (Left, Right : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Pow);

   generic
      type Float_Type is digits <>;
   function Sin (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Sin);

   generic
      type Float_Type is digits <>;
   function Cos (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Cos);

   generic
      type Float_Type is digits <>;
   function Tan (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Tan);

   generic
      type Float_Type is digits <>;
   function Arcsin (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Arcsin);

   generic
      type Float_Type is digits <>;
   function Arccos (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Arccos);

   generic
      type Float_Type is digits <>;
   function Arctan (Y : Float_Type'Base; X : Float_Type'Base := 1.0)
      return Float_Type'Base;
   pragma Inline (Arctan);

   generic
      type Float_Type is digits <>;
   function Sinh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Sinh);

   generic
      type Float_Type is digits <>;
   function Cosh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Cosh);

   generic
      type Float_Type is digits <>;
   function Tanh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Tanh);

   generic
      type Float_Type is digits <>;
   function Arcsinh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Arcsinh);

   generic
      type Float_Type is digits <>;
   function Arccosh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Arccosh);

   generic
      type Float_Type is digits <>;
   function Arctanh (X : Float_Type'Base) return Float_Type'Base;
   pragma Inline (Arctanh);

   Argument_Error : exception
      renames Ada.Numerics.Argument_Error;

end Ada.Float.Elementary_Functions;
