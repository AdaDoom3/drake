pragma License (Unrestricted);
--  extended unit
--  diff (Copy_On_Write)
private with Ada.Containers.Inside.Linked_Lists.Doubly;
private with Ada.Finalization;
--  diff (Streams)
generic
   type Element_Type (<>) is limited private;
--  diff ("=")
package Ada.Containers.Limited_Doubly_Linked_Lists is
   pragma Preelaborate;
--  pragma Remote_Types; -- [gcc 4.5/4.6] it defends to define Reference_Type

   type List is tagged limited private;
   pragma Preelaborable_Initialization (List);

   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);

--  diff
--  Empty_List : constant List;
   function Empty_List return List;

   No_Element : constant Cursor;

   function Has_Element (Position : Cursor) return Boolean;

--  package List_Iterator_Interfaces is new
--     Ada.Iterator_Interfaces (Cursor, Has_Element);
   type Iterator is limited private;
   function First (Object : Iterator) return Cursor;
   function Next (Object : Iterator; Position : Cursor) return Cursor;
   function Last (Object : Iterator) return Cursor;
   function Previous (Object : Iterator; Position : Cursor) return Cursor;

--  diff ("=")

   function Length (Container : List) return Count_Type;

   function Is_Empty (Container : List) return Boolean;

   procedure Clear (Container : in out List);

--  diff (Element)

--  diff (Replace_Element)
--
--
--

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (Element : Element_Type));

   --  modified
   procedure Update_Element (
      Container : in out List'Class; -- not primitive
      Position : Cursor;
      Process : not null access procedure (Element : in out Element_Type));

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is private;

   type Reference_Type (
      Element : not null access Element_Type) is private;

   function Constant_Reference (
      Container : not null access constant List; -- [gcc 4.5/4.6] aliased
      Position : Cursor)
      return Constant_Reference_Type;

   function Reference (
      Container : not null access List; -- [gcc 4.5/4.6] aliased
      Position : Cursor)
      return Reference_Type;

--  diff (Assign)

--  diff (Copy)

   procedure Move (Target : in out List; Source : in out List);

--  diff (Insert)
--
--
--
--

   procedure Insert (
      Container : in out List;
      Before : Cursor;
      New_Item : not null access function return Element_Type;
      Position : out Cursor;
      Count : Count_Type := 1);

--  diff (Insert)
--
--
--
--

--  diff (Prepend)
--
--
--

--  diff (Append)
--
--
--

   procedure Delete (
      Container : in out List;
      Position : in out Cursor;
      Count : Count_Type := 1);

   procedure Delete_First (Container : in out List; Count : Count_Type := 1);

   procedure Delete_Last (Container : in out List; Count : Count_Type := 1);

   procedure Reverse_Elements (Container : in out List);

   procedure Swap (Container : in out List; I, J : Cursor);

   procedure Swap_Links (Container : in out List; I, J : Cursor);

   procedure Splice (
      Target : in out List;
      Before : Cursor;
      Source : in out List);

   procedure Splice (
      Target : in out List;
      Before : Cursor;
      Source : in out List;
      Position : in out Cursor);

   procedure Splice (
      Container : in out List;
      Before : Cursor;
      Position : Cursor);

   function First (Container : List) return Cursor;

--  diff (First_Element)

   function Last (Container : List) return Cursor;

--  diff (Last_Element)

   function Next (Position : Cursor) return Cursor;

   function Previous (Position : Cursor) return Cursor;

   procedure Next (Position : in out Cursor);

   procedure Previous (Position : in out Cursor);

--  diff (Find)
--
--
--
--
--
--
--
--
--
--
--
--
--

--  diff (Reverse_Find)
--
--
--
--
--
--
--
--
--
--
--
--
--
--

--  diff (Contains)

   --  extended
   function "<" (Left, Right : Cursor) return Boolean;

   --  modified
   procedure Iterate (
      Container : List'Class; -- not primitive
      Process : not null access procedure (Position : Cursor));

   --  modified
   procedure Reverse_Iterate (
      Container : List; -- not primitive
      Process : not null access procedure (Position : Cursor));

--  function Iterate (Container : List)
--    return List_Iterator_Interfaces.Reversible_Iterator'Class;
   function Iterate (Container : List)
      return Iterator;

--  function Iterate (Container : in List; Start : in Cursor)
--    return List_Iterator_Interfaces.Reversible_Iterator'Class;

   --  extended
   function Iterate (Container : List; First, Last : Cursor)
      return Iterator;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting is
      function Is_Sorted (Container : List) return Boolean;
      procedure Sort (Container : in out List);
      procedure Merge (Target : in out List; Source : in out List);
   end Generic_Sorting;

   generic
      with function "=" (Left, Right : Element_Type) return Boolean is <>;
   package Equivalents is
      function "=" (Left, Right : List) return Boolean;
      function Find (Container : List; Item : Element_Type) return Cursor;
      function Find (Container : List;
                     Item : Element_Type;
                     Position : Cursor) return Cursor;
      function Reverse_Find (Container : List;
                             Item : Element_Type) return Cursor;
      function Reverse_Find (Container : List;
                             Item : Element_Type;
                             Position : Cursor) return Cursor;
      function Contains (Container : List; Item : Element_Type) return Boolean;
   end Equivalents;

private

   package Linked_Lists renames Containers.Inside.Linked_Lists;
   package Base renames Linked_Lists.Doubly;
--  diff (Copy_On_Write)

   type Element_Access is access Element_Type;

   type Node is limited record
      Super : aliased Base.Node;
      Element : Element_Access;
   end record;

   --  place Super at first whether Element_Type is controlled-type
   for Node use record
      Super at 0 range 0 .. Base.Node_Size - 1;
   end record;

--  diff (Data)
--
--
--
--
--

--  diff (Data_Access)

   type List is new Finalization.Limited_Controlled with record
      First : Linked_Lists.Node_Access := null;
      Last : Linked_Lists.Node_Access := null;
      Length : Count_Type := 0;
   end record;

--  diff (Adjust)
   overriding procedure Finalize (Object : in out List)
      renames Clear;

--  different line (stream attributes are unimplemented)
--
--
--
--
--
--
--

--  diff ('Read)
--  diff ('Write)

   type Cursor is access Node;

   No_Element : constant Cursor := null;

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is null record;

   type Reference_Type (
      Element : not null access Element_Type) is null record;

   type Iterator is record
      First : Cursor;
      Last : Cursor;
   end record;

end Ada.Containers.Limited_Doubly_Linked_Lists;
