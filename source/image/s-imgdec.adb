package body System.Img_Dec is
   pragma Suppress (All_Checks);

   procedure Image_Decimal (
      V : Integer;
      S : in out String;
      P : out Natural;
      Scale : Integer) is
   begin
      raise Program_Error;
   end Image_Decimal;

end System.Img_Dec;
