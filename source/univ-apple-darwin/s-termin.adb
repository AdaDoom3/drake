with Ada.Unchecked_Conversion;
with System.Native_Stack;
with System.Unwind.Raising;
with System.Unwind.Standard;
with C.stdlib;
with C.string;
with C.sys.types;
with C.sys.ucontext;
with C.unistd;
package body System.Termination is
   pragma Suppress (All_Checks);
   use type C.signed_int;
   use type C.signed_long;
   use type C.size_t;
   use type C.unsigned_int;
   use type C.unsigned_long;

   procedure Error_Put (S : String) is
      Dummy : C.sys.types.ssize_t;
      pragma Unreferenced (Dummy);
   begin
      Dummy := C.unistd.write (
         C.unistd.STDERR_FILENO,
         C.void_const_ptr (S'Address),
         S'Length);
   end Error_Put;

   procedure Error_New_Line is
   begin
      Error_Put ((1 => Character'Val (10)));
   end Error_New_Line;

   procedure Force_Abort is
   begin
      C.stdlib.C_abort;
   end Force_Abort;

   procedure Register_Exit (Handler : not null Exit_Handler) is
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
   begin
      --  atexit requires handler that has C calling-convention,
      --  but Ada procedure having no argument is same as C.
      Dummy := C.stdlib.atexit (Handler);
   end Register_Exit;

   procedure sigaction_Handler (
      Signal_Number : C.signed_int;
      Info : access C.signal.siginfo_t;
      Context : C.void_ptr);
   pragma Convention (C, sigaction_Handler);
   pragma No_Return (sigaction_Handler);
   procedure sigaction_Handler (
      Signal_Number : C.signed_int;
      Info : access C.signal.siginfo_t;
      Context : C.void_ptr)
   is
      pragma Unreferenced (Info);
--    pragma Unreferenced (Context);
      function Cast is new Ada.Unchecked_Conversion (C.void_ptr, Address);
      C_Message : constant C.char_ptr := C.string.strsignal (Signal_Number);
      subtype Fixed_String is String (Positive);
      Message : Fixed_String;
      for Message'Address use C_Message.all'Address;
      Eexception_Id : Unwind.Exception_Data_Access;
      Stack_Guard : Address := Null_Address;
      Dummy : Address;
   begin
      case Signal_Number is
         when C.signal.SIGFPE =>
            Eexception_Id := Unwind.Standard.Constraint_Error'Access;
         when C.signal.SIGBUS | C.signal.SIGSEGV =>
            Native_Stack.Get (Top => Stack_Guard, Bottom => Dummy);
            Stack_Guard := Stack_Guard + C.signal.MINSIGSTKSZ;
            declare
               uc : C.sys.ucontext.ucontext_t;
               pragma Import (C, uc);
               for uc'Address use Cast (Context);
               pragma Inspection_Point (uc);
            begin
               null; -- probe uc for debugging
            end;
            Native_Stack.Fake_Return_From_Signal_Handler;
            Eexception_Id := Unwind.Standard.Storage_Error'Access;
         when others =>
            Eexception_Id := Unwind.Standard.Program_Error'Access;
      end case;
      Unwind.Raising.Raise_From_Signal_Handler (
         Eexception_Id,
         Message => Message (1 .. Integer (C.string.strlen (C_Message))),
         Stack_Guard => Stack_Guard);
   end sigaction_Handler;

   Signal_Stack : aliased Signal_Stack_Type;

   procedure Install_Exception_Handler (SEH : Address) is
      pragma Unreferenced (SEH);
      act : aliased C.signal.struct_sigaction := (
         (Unchecked_Tag => 1, sa_sigaction => sigaction_Handler'Access),
         others => <>);
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
   begin
      act.sa_flags := C.signed_int (C.unsigned_int'(
         C.signal.SA_NODEFER
         or C.signal.SA_RESTART
         or C.signal.SA_SIGINFO));
      Dummy := C.signal.sigemptyset (act.sa_mask'Access);
      --  illegal instruction
      Dummy := C.signal.sigaction (C.signal.SIGILL, act'Access, null);
      --  floating-point exception
      Dummy := C.signal.sigaction (C.signal.SIGFPE, act'Access, null);
      --  bus error
      Set_Signal_Stack (Signal_Stack'Access);
      act.sa_flags := C.signed_int (C.unsigned_int (act.sa_flags)
         or C.signal.SA_ONSTACK);
      Dummy := C.signal.sigaction (C.signal.SIGBUS, act'Access, null);
      --  segmentation violation
      Dummy := C.signal.sigaction (C.signal.SIGSEGV, act'Access, null);
   end Install_Exception_Handler;

   procedure Set_Signal_Stack (S : access Signal_Stack_Type) is
      function Cast is
         new Ada.Unchecked_Conversion (C.char_ptr, C.void_ptr); -- OSX
      function Cast is
         new Ada.Unchecked_Conversion (C.char_ptr, C.char_ptr); -- FreeBSD
      pragma Warnings (Off, Cast);
      stack : aliased C.signal.stack_t := (
         ss_sp => Cast (S (S'First)'Access),
         ss_size => Signal_Stack_Type'Size / Standard'Storage_Unit,
         ss_flags => 0);
      Dummy : C.signed_int;
      pragma Unreferenced (Dummy);
   begin
      Dummy := C.signal.sigaltstack (stack'Access, null);
   end Set_Signal_Stack;

end System.Termination;
