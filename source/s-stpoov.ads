pragma License (Unrestricted);
--  implementation unit for System.Initialization
package System.Storage_Pools.Overlaps is
   pragma Preelaborate;

   type Overlay_Pool is new Root_Storage_Pool with null record;
   --  actually, an allocation address is stored in TLS

   procedure Set_Address (Storage_Address : Address);
   pragma Inline (Set_Address);

   overriding procedure Allocate (
      Pool : in out Overlay_Pool;
      Storage_Address : out Address;
      Size_In_Storage_Elements : Storage_Elements.Storage_Count;
      Alignment : Storage_Elements.Storage_Count);
   pragma Inline (Allocate);

   overriding procedure Deallocate (
      Pool : in out Overlay_Pool;
      Storage_Address : Address;
      Size_In_Storage_Elements : Storage_Elements.Storage_Count;
      Alignment : Storage_Elements.Storage_Count);
   pragma Inline (Deallocate);

   overriding function Storage_Size (Pool : Overlay_Pool)
      return Storage_Elements.Storage_Count;
   pragma Inline (Storage_Size);

   Pool : Overlay_Pool;
   --  if a local pool is declared, all objects belongs to the local scope,
   --  then there be finalized when the local pool is out of scope...
   --  therefore it should use global pool

end System.Storage_Pools.Overlaps;
