pragma License (Unrestricted);
--  Ada 2005
private with Ada.Containers.Inside.Copy_On_Write;
private with Ada.Containers.Inside.Hash_Tables;
private with Ada.Finalization;
private with Ada.Streams;
generic
   type Element_Type (<>) is private;
   with function Hash (Element : Element_Type) return Hash_Type;
   with function Equivalent_Elements (Left, Right : Element_Type)
      return Boolean;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
package Ada.Containers.Indefinite_Hashed_Sets is
   pragma Preelaborate;
--  pragma Remote_Types; --  it defends to define Reference_Type...

   type Set is tagged private;
   pragma Preelaborable_Initialization (Set);

   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);

--  Empty_Set : constant Set;
   function Empty_Set return Set;

--  No_Element : constant Cursor;
   function No_Element return Cursor;

   function "=" (Left, Right : Set) return Boolean;

   function Equivalent_Sets (Left, Right : Set) return Boolean;

   function To_Set (New_Item : Element_Type) return Set;

   function Capacity (Container : Set) return Count_Type;

   procedure Reserve_Capacity (
      Container : in out Set;
      Capacity : Count_Type);

   function Length (Container : Set) return Count_Type;

   function Is_Empty (Container : Set) return Boolean;

   procedure Clear (Container : in out Set);

   function Element (Position : Cursor) return Element_Type;

   procedure Replace_Element (
      Container : in out Set;
      Position : Cursor;
      New_Item : Element_Type);

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (Element : Element_Type));

   procedure Assign (Target : in out Set; Source : Set);

   function Copy (Source : Set; Capacity : Count_Type := 0) return Set;

   procedure Move (Target : in out Set; Source : in out Set);

   procedure Insert (
      Container : in out Set;
      New_Item : Element_Type;
      Position : out Cursor;
      Inserted : out Boolean);

   procedure Insert (Container : in out Set; New_Item : Element_Type);

   procedure Include (Container : in out Set; New_Item : Element_Type);

   procedure Replace (Container : in out Set; New_Item : Element_Type);

   procedure Exclude (Container : in out Set; Item : Element_Type);

   procedure Delete (Container : in out Set; Item : Element_Type);

   procedure Delete (Container : in out Set; Position : in out Cursor);

   procedure Union (Target : in out Set; Source : Set);

   function Union (Left, Right : Set) return Set;

   function "or" (Left, Right : Set) return Set
      renames Union;

   procedure Intersection (Target : in out Set; Source : Set);

   function Intersection (Left, Right : Set) return Set;

   function "and" (Left, Right : Set) return Set
      renames Intersection;

   procedure Difference (Target : in out Set; Source : Set);

   function Difference (Left, Right : Set) return Set;

   function "-" (Left, Right : Set) return Set
      renames Difference;

   procedure Symmetric_Difference (Target : in out Set; Source : Set);

   function Symmetric_Difference (Left, Right : Set) return Set;

   function "xor" (Left, Right : Set) return Set
      renames Symmetric_Difference;

   function Overlap (Left, Right : Set) return Boolean;

   function Is_Subset (Subset : Set; Of_Set : Set) return Boolean;

   function First (Container : Set) return Cursor;

   --  extended
   function Last (Container : Set) return Cursor;

   function Next (Position : Cursor) return Cursor;

   procedure Next (Position : in out Cursor);

   function Find (Container : Set; Item : Element_Type) return Cursor;

   function Contains (Container : Set; Item : Element_Type) return Boolean;

   function Has_Element (Position : Cursor) return Boolean;

--  function Equivalent_Elements (Left, Right : Cursor) return Boolean;

   function Equivalent_Elements (Left : Cursor; Right : Element_Type)
      return Boolean;

--  function Equivalent_Elements (Left : Element_Type; Right : Cursor)
--    return Boolean;

   --  extended
   function "<=" (Left, Right : Cursor) return Boolean;

   procedure Iterate (
      Container : Set;
      Process : not null access procedure (Position : Cursor));

   --  AI05-0212-1
   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is limited private;
   type Reference_Type (
      Element : not null access Element_Type) is limited private;
   function Constant_Reference (
      Container : not null access constant Set;
      Position : Cursor)
      return Constant_Reference_Type;
   function Reference (
      Container : not null access Set;
      Position : Cursor)
      return Reference_Type;

   generic
      type Key_Type (<>) is private;
      with function Key (Element : Element_Type) return Key_Type;
      with function Hash (Key : Key_Type) return Hash_Type;
      with function Equivalent_Keys (Left, Right : Key_Type) return Boolean;
   package Generic_Keys is

      function Key (Position : Cursor) return Key_Type;

      function Element (Container : Set; Key : Key_Type) return Element_Type;

      procedure Replace (
         Container : in out Set;
         Key : Key_Type;
         New_Item : Element_Type);

      procedure Exclude (Container : in out Set; Key : Key_Type);

      procedure Delete (Container : in out Set; Key : Key_Type);

      function Find (Container : Set; Key : Key_Type) return Cursor;

      function Contains (Container : Set; Key : Key_Type) return Boolean;

      procedure Update_Element_Preserving_Key (
         Container : in out Set;
         Position : Cursor;
         Process : not null access procedure (Element : in out Element_Type));

   end Generic_Keys;

--  diff (Equivalents)
--
--
--
--
--

private

   package Hash_Tables renames Containers.Inside.Hash_Tables;
   package Copy_On_Write renames Containers.Inside.Copy_On_Write;

   type Element_Access is access Element_Type;

   type Node is limited record
      Super : aliased Hash_Tables.Node;
      Element : Element_Access;
   end record;

   type Cursor is access Node;

   type Data is limited record
      Super : aliased Copy_On_Write.Data;
      Table : Hash_Tables.Table_Access := null;
      Length : Count_Type := 0;
   end record;

   type Data_Access is access Data;

   type Set is new Finalization.Controlled with record
      Super : aliased Copy_On_Write.Container;
--  diff
   end record;

   overriding procedure Adjust (Object : in out Set);
   overriding procedure Finalize (Object : in out Set)
      renames Clear;

   package No_Primitives is
      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Set);
      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Set);
   end No_Primitives;

   for Set'Read use No_Primitives.Read;
   for Set'Write use No_Primitives.Write;

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is limited null record;

   type Reference_Type (
      Element : not null access Element_Type) is limited null record;

end Ada.Containers.Indefinite_Hashed_Sets;