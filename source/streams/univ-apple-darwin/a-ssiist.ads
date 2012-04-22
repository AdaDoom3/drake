pragma License (Unrestricted);
--  implementation unit
package Ada.Streams.Stream_IO.Inside.Standards is

   Standard_Input : constant Non_Controlled_File_Type;
   Standard_Output : constant Non_Controlled_File_Type;
   Standard_Error : constant Non_Controlled_File_Type;

private

   Standard_Input_Stream : aliased Stream_Type := (
      Name_Length => 6,
      Form_Length => 0,
      Dispatcher => (others => <>),
      Handle => 0,
      Mode => In_File,
      Kind => Standard_Handle,
      Buffer => <>,
      Last => 0,
      Name => "*stdin",
      Form => "");

   Standard_Output_Stream : aliased Stream_Type := (
      Name_Length => 7,
      Form_Length => 0,
      Dispatcher => (others => <>),
      Handle => 1,
      Mode => Out_File,
      Kind => Standard_Handle,
      Buffer => <>,
      Last => 0,
      Name => "*stdout",
      Form => "");

   Standard_Error_Stream : aliased Stream_Type := (
      Name_Length => 7,
      Form_Length => 0,
      Dispatcher => (others => <>),
      Handle => 2,
      Mode => Out_File,
      Kind => Standard_Handle,
      Buffer => <>,
      Last => 0,
      Name => "*stderr",
      Form => "");

   Standard_Input : constant Non_Controlled_File_Type :=
      Standard_Input_Stream'Access;
   Standard_Output : constant Non_Controlled_File_Type :=
      Standard_Output_Stream'Access;
   Standard_Error : constant Non_Controlled_File_Type :=
      Standard_Error_Stream'Access;

end Ada.Streams.Stream_IO.Inside.Standards;
