with Ada.Unchecked_Conversion;
with Ada.Finalization;
with System.Address_To_Access_Conversions;
package body Ada.Exceptions.Finally is
   pragma Suppress (All_Checks);
   use type System.Address;

   type Handler_Type is access procedure (Params : System.Address);

   type Finalizer is new Finalization.Limited_Controlled with record
      Params : System.Address;
      Handler : System.Address;
   end record;
   pragma Discard_Names (Finalizer);

   overriding procedure Finalize (Object : in out Finalizer);
   overriding procedure Finalize (Object : in out Finalizer) is
      function Cast is new Unchecked_Conversion (System.Address, Handler_Type);
   begin
      if Object.Params /= System.Null_Address then
         Cast (Object.Handler).all (Object.Params);
      end if;
   end Finalize;

   --  implementation

   package body Scoped_Holder is

      package Conv is new System.Address_To_Access_Conversions (Parameters);

      Object : Finalizer := (
         Finalization.Limited_Controlled with
         Params => System.Null_Address,
         Handler => Handler'Code_Address);
      pragma Unreferenced (Object);

      procedure Assign (Item : access Parameters) is
      begin
         Object.Params := Conv.To_Address (Conv.Object_Pointer (Item));
      end Assign;

      procedure Clear is
      begin
         Object.Params := System.Null_Address;
      end Clear;

   end Scoped_Holder;

   procedure Try_Finally (
      Params : System.Address;
      Process : not null access procedure (Params : System.Address);
      Handler : not null access procedure (Params : System.Address))
   is
      Object : Finalizer := (
         Finalization.Limited_Controlled with
         Params => Params,
         Handler => Handler.all'Address);
      pragma Unreferenced (Object);
   begin
      Process.all (Params);
   end Try_Finally;

   procedure Try_When_All (
      Params : System.Address;
      Process : not null access procedure (Params : System.Address);
      Handler : not null access procedure (Params : System.Address))
   is
      Object : Finalizer := (
         Finalization.Limited_Controlled with
         Params => Params,
         Handler => Handler.all'Address);
      pragma Unreferenced (Object);
   begin
      Process.all (Params);
      Object.Params := System.Null_Address;
   end Try_When_All;

end Ada.Exceptions.Finally;
