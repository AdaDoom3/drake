pragma License (Unrestricted);
--  translated unit from SFMT
generic
   --  Mersenne Exponent. The period of the sequence
   --  is a multiple of 2^MEXP-1.
   MEXP : Natural := 19937;
   --  the pick up position of the array.
   POS1 : Natural := 122;
   --  the parameter of shift left as four 32-bit registers.
   SL1 : Natural := 18;
   --  the parameter of shift left as one 128-bit register.
   --  The 128-bit integer is shifted by (SL2 * 8) bits.
   SL2 : Natural := 1;
   --  the parameter of shift right as four 32-bit registers.
   SR1 : Natural := 11;
   --  the parameter of shift right as one 128-bit register.
   --  The 128-bit integer is shifted by (SL2 * 8) bits.
   SR2 : Natural := 1;
   --  A bitmask, used in the recursion.  These parameters are introduced
   --  to break symmetry of SIMD.
   MSK1 : Unsigned_32 := 16#dfffffef#;
   MSK2 : Unsigned_32 := 16#ddfecb7f#;
   MSK3 : Unsigned_32 := 16#bffaffff#;
   MSK4 : Unsigned_32 := 16#bffffff6#;
   --  These definitions are part of a 128-bit period certification vector.
   PARITY1 : Unsigned_32 := 16#00000001#;
   PARITY2 : Unsigned_32 := 16#00000000#;
   PARITY3 : Unsigned_32 := 16#00000000#;
   PARITY4 : Unsigned_32 := 16#c98e126a#;
package Ada.Numerics.SFMT.Random is
   pragma Preelaborate;

   function Id return String;

   type Generator is limited private;

   function Random_32 (Gen : not null access Generator) return Unsigned_32;
   function Random_64 (Gen : not null access Generator) return Unsigned_64;

   procedure Fill_Random_32 (
      Gen : in out Generator;
      Item : out Unsigned_32_Array);
   procedure Fill_Random_64 (
      Gen : in out Generator;
      Item : out Unsigned_64_Array);

   function Initialize return Generator;
   function Initialize (Initiator : Unsigned_32) return Generator;
   function Initialize (Initiator : Unsigned_32_Array) return Generator;

   procedure Reset (Gen : in out Generator);
   procedure Reset (Gen : in out Generator; Initiator : Integer);

   type State is private;
   pragma Preelaborable_Initialization (State); -- uninitialized

   function Initialize return State;
   function Initialize (Initiator : Unsigned_32) return State;
   function Initialize (Initiator : Unsigned_32_Array) return State;

   procedure Save (Gen : Generator; To_State : out State);
   procedure Reset (Gen : in out Generator; From_State : State);
   function Reset (From_State : State) return Generator;

   Max_Image_Width : constant Natural;

   function Image (Of_State : State) return String;
   function Value (Coded_State : String) return State;

   Default_Initiator : constant := 1234; -- test.c

   --  This constant means the minimum size of array used for
   --  Fill_Random_32 procedure.
   Min_Array_Length_32 : constant Natural;
   pragma Warnings (Off, Min_Array_Length_32);
   --  This constant means the minimum size of array used for
   --  Fill_Random_64 procedure.
   Min_Array_Length_64 : constant Natural;
   pragma Warnings (Off, Min_Array_Length_64);

   subtype Uniformly_Distributed is Long_Long_Float range 0.0 .. 1.0;

   function To_0_To_1 (v : Unsigned_32)
      return Uniformly_Distributed;
   pragma Inline (To_0_To_1);

   function Random_0_To_1 (Gen : not null access Generator)
      return Uniformly_Distributed;
   pragma Inline (Random_0_To_1);

   function To_0_To_Less_1 (v : Unsigned_32)
      return Uniformly_Distributed;
   pragma Inline (To_0_To_Less_1);

   function Random_0_To_Less_1 (Gen : not null access Generator)
      return Uniformly_Distributed;
   pragma Inline (Random_0_To_Less_1);

   function To_Greater_0_To_Less_1 (v : Unsigned_32)
      return Uniformly_Distributed;
   pragma Inline (To_Greater_0_To_Less_1);

   function Random_Greater_0_To_Less_1 (Gen : not null access Generator)
      return Uniformly_Distributed;
   pragma Inline (Random_Greater_0_To_Less_1);

   function To_53_0_To_Less_1 (v : Unsigned_64)
      return Uniformly_Distributed;
   pragma Inline (To_53_0_To_Less_1);

   function Random_53_0_To_Less_1 (Gen : not null access Generator)
      return Uniformly_Distributed;
   pragma Inline (Random_53_0_To_Less_1);

private

   --  SFMT generator has an internal state array of 128-bit integers,
   --  and N is its size.
   N : constant Natural := MEXP / 128 + 1;
   --  N32 is the size of internal state array when regarded as an array
   --  of 32-bit integers.
   Min_Array_Length_32 : constant Natural := N * 4;
   N32 : Natural renames Min_Array_Length_32;
   --  N64 is the size of internal state array when regarded as an array
   --  of 64-bit integers.
   Min_Array_Length_64 : constant Natural := N * 2;
   N64 : Natural renames Min_Array_Length_64;

   Max_Image_Width : constant Natural := (N32 + 1) * (32 / 4 + 1) - 1;

   subtype Unsigned_32_Array_N32 is Unsigned_32_Array (0 .. N32 - 1);

   --  128-bit data type
   type w128_t is array (0 .. 3) of Unsigned_32;
   pragma Suppress_Initialization (w128_t);
   type w128_t_Array is array (Natural range <>) of aliased w128_t;
   for w128_t_Array'Alignment use 16;
   pragma Suppress_Initialization (w128_t_Array);

   subtype w128_t_Array_N is w128_t_Array (0 .. N - 1);
   subtype w128_t_Array_Fixed is w128_t_Array (Natural);

   --  internal state, index counter and flag
   type State (Unchecked_Tag : Natural := 0) is record
      case Unchecked_Tag is
         when 0 =>
            --  the 128-bit internal state array
            sfmt : aliased w128_t_Array_N;
            --  index counter to the 32-bit internal state array
            idx : Integer;
         when 1 =>
            --  the 32bit integer pointer
            --  to the 128-bit internal state array
            psfmt32 : aliased Unsigned_32_Array_N32;
         when others =>
            --  the 64bit integer pointer
            --  to the 128-bit internal state array
            psfmt64 : aliased Unsigned_64_Array (0 .. N64 - 1);
      end case;
   end record;
   pragma Unchecked_Union (State);
   pragma Suppress_Initialization (State);

   type Generator is limited record
      State : Random.State := Initialize (Default_Initiator);
   end record;

   --  a parity check vector which certificate the period of 2^{MEXP}
   parity : constant Unsigned_32_Array (0 .. 3) :=
      (PARITY1, PARITY2, PARITY3, PARITY4);

end Ada.Numerics.SFMT.Random;
