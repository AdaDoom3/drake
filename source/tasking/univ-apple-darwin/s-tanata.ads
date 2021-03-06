pragma License (Unrestricted);
--  implementation unit
with C.pthread;
package System.Tasking.Native_Tasks is
   pragma Preelaborate;

   type Task_Attribute_Of_Abort;

   --  thread

   subtype Handle_Type is C.pthread.pthread_t;

   function Current return Handle_Type
      renames C.pthread.pthread_self;

   subtype Parameter_Type is C.void_ptr;
   subtype Result_Type is C.void_ptr;

   type Thread_Body_Type is access
      function (Parameter : Parameter_Type) return Result_Type;
   pragma Convention (C, Thread_Body_Type);
   pragma Convention_Identifier (Thread_Body_CC, C);

   procedure Create (
      Handle : not null access Handle_Type;
      Parameter : Parameter_Type;
      Thread_Body : Thread_Body_Type;
      Error : out Boolean);

   procedure Join (
      Handle : Handle_Type; -- of target thread
      Abort_Current : access Task_Attribute_Of_Abort; -- of current thread
      Result : not null access Result_Type;
      Error : out Boolean);
   procedure Detach (
      Handle : Handle_Type;
      Error : out Boolean);

   --  stack

   subtype Info_Block_Type is Handle_Type;

   type Task_Attribute_Of_Stack is null record;
   pragma Suppress_Initialization (Task_Attribute_Of_Stack);

   procedure Initialize (Attr : in out Task_Attribute_Of_Stack) is null;
   procedure Finalize (Attr : in out Task_Attribute_Of_Stack) is null;

   function Info_Block (
      Handle : Handle_Type;
      Attr : Task_Attribute_Of_Stack)
      return Info_Block_Type;
   pragma Inline (Info_Block);

   --  signals

   type Abort_Handler is access procedure;

   procedure Install_Abort_Handler (Handler : Abort_Handler);
   procedure Uninstall_Abort_Handler;

   type Task_Attribute_Of_Abort is null record;
   pragma Suppress_Initialization (Task_Attribute_Of_Abort);

   procedure Initialize (Attr : in out Task_Attribute_Of_Abort) is null;
   procedure Finalize (Attr : in out Task_Attribute_Of_Abort) is null;

   procedure Send_Abort_Signal (
      Handle : Handle_Type;
      Attr : Task_Attribute_Of_Abort;
      Error : out Boolean);

   procedure Block_Abort_Signal (Attr : in out Task_Attribute_Of_Abort);
   procedure Unblock_Abort_Signal (Attr : in out Task_Attribute_Of_Abort);

end System.Tasking.Native_Tasks;
