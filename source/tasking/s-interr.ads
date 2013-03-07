pragma License (Unrestricted);
--  implementation unit required by compiler
with Ada.Interrupts;
with System.Tasking.Protected_Objects;
with System.Tasking.Protected_Objects.Entries;
package System.Interrupts is
   pragma Elaborate_Body;

--  type Previous_Handler_Item is record
--    Interrupt : Ada.Interrupts.Interrupt_Id;
--    Handler : Ada.Interrupts.Parameterless_Handler;
--    Static : Boolean;
--  end record;
--  pragma Suppress_Initialization (Previous_Handler_Item);

--  type Previous_Handler_Array is
--    array (Positive range <>) of Previous_Handler_Item;
--  pragma Suppress_Initialization (Previous_Handler_Array);

   type New_Handler_Item is record
      Interrupt : Ada.Interrupts.Interrupt_Id;
      Handler : Ada.Interrupts.Parameterless_Handler;
   end record;
   pragma Suppress_Initialization (New_Handler_Item);

   type New_Handler_Array is array (Positive range <>) of New_Handler_Item;
   pragma Suppress_Initialization (New_Handler_Array);

   --  required by compiler

   subtype System_Interrupt_Id is Ada.Interrupts.Interrupt_Id;

   Default_Interrupt_Priority : constant Interrupt_Priority :=
      Interrupt_Priority'Last;

   --  required to attach a protected handler by compiler

   type Static_Interrupt_Protection (
      Num_Entries : Tasking.Protected_Objects.Protected_Entry_Index;
      Num_Attach_Handler : Natural) is
      new Tasking.Protected_Objects.Entries.Protection_Entries (
         Num_Entries) with null record;
--  record
--    Previous_Handlers : Previous_Handler_Array (1 .. Num_Attach_Handler);
--  end record;

   procedure Register_Interrupt_Handler (Handler_Addr : Address) is
      null;

   procedure Install_Handlers (
      Object : not null access Static_Interrupt_Protection;
      New_Handlers : New_Handler_Array);

   --  unimplemented subprograms required by compiler
   --  Bind_Interrupt_To_Entry
   --  Dynamic_Interrupt_Protection
   --  Install_Restricted_Handlers

end System.Interrupts;