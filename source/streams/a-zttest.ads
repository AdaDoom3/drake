pragma License (Unrestricted);
with Ada.Streams.Stream_IO;
package Ada.Wide_Wide_Text_IO.Text_Streams is

--  type Stream_Access is access all Streams.Root_Stream_Type'Class;
   subtype Stream_Access is Streams.Stream_IO.Stream_Access;

   function Stream (File : File_Type) return Stream_Access;

end Ada.Wide_Wide_Text_IO.Text_Streams;
