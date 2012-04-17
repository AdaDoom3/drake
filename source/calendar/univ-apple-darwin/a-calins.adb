with Ada.Unchecked_Conversion;
with System.Native_Time;
with C.time;
with C.sys.types;
package body Ada.Calendar.Inside is
   pragma Suppress (All_Checks);
   use type C.signed_int; -- time_t is signed int or signed long
   use type C.signed_long;

   type Time_Rep is range
      -(2 ** (Time'Size - 1)) ..
      +(2 ** (Time'Size - 1)) - 1;
   for Time_Rep'Size use Time'Size;

   --  implementation

   function Seconds (Date : Time; Time_Zone : Time_Offset)
      return Day_Duration
   is
      function Cast is new Unchecked_Conversion (Time, Time_Rep);
      function Cast is new Unchecked_Conversion (Time_Rep, Duration);
   begin
      return Cast ((Cast (Date) + Time_Rep (Time_Zone) * (60 * 1000000000)) mod
         (24 * 60 * 60 * 1000000000));
   end Seconds;

   procedure Split (
      Seconds : Duration;
      Hour : out Natural;
      Minute : out Minute_Number;
      Second : out Second_Number;
      Sub_Second : out Second_Duration)
   is
      function Cast is new Unchecked_Conversion (Duration, Time_Rep);
      function Cast is new Unchecked_Conversion (Time_Rep, Duration);
      X : Time_Rep := Cast (Seconds); -- unit is 1-nanoscond
   begin
      Sub_Second := Cast (X rem 1000000000);
      X := (X - Cast (Sub_Second)) / 1000000000; -- unit is 1-second
      Second := Second_Number (X rem 60);
      X := (X - Time_Rep (Second)) / 60; -- unit is 1-minute
      Minute := Minute_Number (X rem 60);
      X := (X - Time_Rep (Minute)) / 60;
      Hour := Integer (X);
   end Split;

   procedure Split (
      Date : Time;
      Year : out Year_Number;
      Month : out Month_Number;
      Day : out Day_Number;
      Hour : out Hour_Number;
      Minute : out Minute_Number;
      Second : out Second_Number;
      Sub_Second : out Second_Duration;
      Leap_Second : out Boolean;
      Day_of_Week : out Day_Name;
      Time_Zone : Time_Offset)
   is
      function Cast is new Unchecked_Conversion (Time_Rep, Duration);
      timespec : aliased System.Native_Time.Native_Time :=
         System.Native_Time.To_Native_Time (Duration (Date));
      Buffer : aliased C.time.struct_tm := (others => <>); -- uninitialized
      tm : access C.time.struct_tm;
   begin
      Sub_Second := Cast (Time_Rep (timespec.tv_nsec));
      timespec.tv_sec := timespec.tv_sec + C.sys.types.time_t (Time_Zone) * 60;
      tm := C.time.gmtime_r (timespec.tv_sec'Access, Buffer'Access);
      --  does gmtime_r return no error ?
      Year := Year_Number (tm.tm_year + 1900);
      Month := Month_Number (tm.tm_mon + 1);
      Day := Day_Number (tm.tm_mday);
      Hour := Hour_Number (tm.tm_hour);
      Minute := Minute_Number (tm.tm_min);
      Second := Second_Number (tm.tm_sec);
      Day_of_Week := Day_Name ((tm.tm_wday + 6) rem 7); -- starts from Monday
      Leap_Second := False;
   end Split;

   function Time_Of (
      Year : Year_Number;
      Month : Month_Number;
      Day : Day_Number;
      Seconds : Day_Duration;
      Leap_Second : Boolean := False;
      Time_Zone : Time_Offset)
      return Time
   is
      pragma Unreferenced (Leap_Second);
      tm : aliased C.time.struct_tm := (
         tm_sec => 0,
         tm_min => 0,
         tm_hour => 0,
         tm_mday => C.signed_int (Day),
         tm_mon => C.signed_int (Month) - 1,
         tm_year => C.signed_int (Year) - 1900,
         tm_wday => 0,
         tm_yday => 0,
         tm_isdst => 0,
         tm_gmtoff => 0,
         tm_zone => null);
      C_Result : constant C.sys.types.time_t := C.time.timegm (tm'Access);
      Result : Time;
   begin
      --  UNIX time starts until 1970, Year_Number stats unitl 1901...
      if C_Result = -1 then
         if Year = 1901 and then Month = 1 and then Day = 1 then
            Result := -7857734400.0; -- first day in Time
         else
            raise Time_Error;
         end if;
      else
         Result := Time (System.Native_Time.To_Time (C_Result));
      end if;
      return Result - Duration (Time_Zone * 60) + Seconds;
   end Time_Of;

end Ada.Calendar.Inside;
