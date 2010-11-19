package body System.Compare_Array_Unsigned_32 is
   pragma Suppress (All_Checks);

   function Compare_Array_U32 (
      Left : Address;
      Right : Address;
      Left_Len : Natural;
      Right_Len : Natural)
      return Integer
   is
      L : Wide_Wide_String (1 .. Left_Len);
      for L'Address use Left;
      R : Wide_Wide_String (1 .. Right_Len);
      for R'Address use Right;
   begin
      for I in 1 .. Integer'Min (Left_Len, Right_Len) loop
         if L (I) < R (I) then
            return -1;
         elsif L (I) > R (I) then
            return 1;
         end if;
      end loop;
      if Left_Len < Right_Len then
         return -1;
      elsif Left_Len > Right_Len then
         return 1;
      else
         return 0;
      end if;
   end Compare_Array_U32;

end System.Compare_Array_Unsigned_32;
