with Ada.Exception_Identification.From_Here;
with System.Native_Time;
with C.time;
with C.sys.types;
package body Ada.Calendar.Inside.Time_Zones is
   pragma Suppress (All_Checks);
   use Exception_Identification.From_Here;
   use type C.sys.types.time_t;

   function UTC_Time_Offset (Date : Time := Clock) return Time_Offset is
      --  FreeBSD does not have timezone variable
      GMT_Time : aliased constant System.Native_Time.Native_Time :=
         System.Native_Time.To_Native_Time (Duration (Date));
      Local_TM : aliased C.time.struct_tm;
      Local_Time : aliased C.sys.types.time_t;
      Dummy : C.time.struct_tm_ptr;
      pragma Unreferenced (Dummy);
   begin
      Dummy := C.time.localtime_r (GMT_Time.tv_sec'Access, Local_TM'Access);
      Local_Time := C.time.timegm (Local_TM'Access);
      if Local_Time = -1 then
         Raise_Exception (Time_Error'Identity);
      end if;
      return Time_Offset ((Local_Time - GMT_Time.tv_sec) / 60);
   end UTC_Time_Offset;

begin
   C.time.tzset;
end Ada.Calendar.Inside.Time_Zones;
