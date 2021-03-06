pragma License (Unrestricted);
--  with System;
--  with System.Multiprocessors;
package Ada.Interrupts is

   type Interrupt_Id is range 0 .. 2 ** 16 - 1; -- implementation-defined
   type Parameterless_Handler is access protected procedure;

   function Is_Reserved (Interrupt : Interrupt_Id) return Boolean;
   pragma Inline (Is_Reserved); -- renamed

   function Is_Attached (Interrupt : Interrupt_Id) return Boolean;
   pragma Inline (Is_Attached);

   function Current_Handler (Interrupt : Interrupt_Id)
      return Parameterless_Handler;
   pragma Inline (Current_Handler); -- renamed

   procedure Attach_Handler (
      New_Handler : Parameterless_Handler;
      Interrupt : Interrupt_Id);
   pragma Inline (Attach_Handler);

   procedure Exchange_Handler (
      Old_Handler : out Parameterless_Handler;
      New_Handler : Parameterless_Handler;
      Interrupt : Interrupt_Id);
   pragma Inline (Exchange_Handler); -- renamed

   procedure Detach_Handler (Interrupt : Interrupt_Id);
   pragma Inline (Detach_Handler);

--  function Reference (Interrupt : Interrupt_Id) return System.Address;

--  function Get_CPU (Interrupt : Interrupt_Id)
--     return System.Multiprocessors.CPU_Range;

   --  extended
   --  Raise a interrupt from/to itself.
   procedure Raise_Interrupt (Interrupt : Interrupt_Id);
   pragma Inline (Raise_Interrupt); -- renamed

end Ada.Interrupts;
