pragma License (Unrestricted);
--  implementation unit specialized for FreeBSD
function System.Memory.Allocated_Size (P : Address)
   return Storage_Elements.Storage_Count;
pragma Preelaborate (System.Memory.Allocated_Size);
