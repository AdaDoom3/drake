package body Ada.Streams.Overlaps_Storage_IO is
   use type System.Storage_Elements.Storage_Offset;

   function Create (
      Address : System.Address;
      Size : System.Storage_Elements.Storage_Count)
      return Overlay is
   begin
      return (Address, Size, 1);
   end Create;

   overriding procedure Read (
      Object : in out Overlay;
      Item : out Stream_Element_Array;
      Last : out Stream_Element_Offset)
   is
      Rest : constant System.Storage_Elements.Storage_Count :=
         Object.Size - Object.Index + 1;
      Size : System.Storage_Elements.Storage_Count := Item'Length;
   begin
      if Size > Rest then
         Size := Rest;
      end if;
      Last := Item'First + Stream_Element_Count (Size) - 1;
      declare
         Source : Stream_Element_Array (1 .. Stream_Element_Offset (Size));
         for Source'Address use Object.Address + Object.Index - 1;
      begin
         Item := Source;
      end;
      Object.Index := Object.Index + Size;
   end Read;

   overriding function Index (Object : Overlay)
      return Stream_Element_Positive_Count is
   begin
      return Stream_Element_Offset (Object.Index);
   end Index;

   overriding procedure Set_Index (
      Object : in out Overlay;
      To : Stream_Element_Positive_Count)
   is
      To_Index : constant System.Storage_Elements.Storage_Offset :=
         System.Storage_Elements.Storage_Offset (To);
   begin
      if To_Index not in 1 .. Object.Size + 1 then
         raise Constraint_Error;
      end if;
      Object.Index := To_Index;
   end Set_Index;

   overriding function Size (Object : Overlay)
      return Stream_Element_Count is
   begin
      return Stream_Element_Count (Object.Size);
   end Size;

   function Stream (Object : Overlay)
      return not null access Root_Stream_Type'Class is
   begin
      return Object'Unrestricted_Access;
   end Stream;

   overriding procedure Write (
      Object : in out Overlay;
      Item : Stream_Element_Array)
   is
      Size : constant System.Storage_Elements.Storage_Count := Item'Length;
      Next_Index : constant System.Storage_Elements.Storage_Offset :=
         Object.Index + Size;
   begin
      if Next_Index > Object.Size + 1 then
         raise Constraint_Error;
      end if;
      declare
         Target : Stream_Element_Array (1 .. Stream_Element_Offset (Size));
         for Target'Address use Object.Address + Object.Index - 1;
      begin
         Target := Item;
      end;
      Object.Index := Next_Index;
   end Write;

end Ada.Streams.Overlaps_Storage_IO;
