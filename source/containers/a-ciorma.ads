pragma License (Unrestricted);
--  Ada 2005
private with Ada.Containers.Inside.Copy_On_Write;
private with Ada.Containers.Inside.Binary_Trees.Arne_Andersson;
private with Ada.Finalization;
private with Ada.Streams;
generic
   type Key_Type (<>) is private;
   type Element_Type (<>) is private;
   with function "<" (Left, Right : Key_Type) return Boolean is <>;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
package Ada.Containers.Indefinite_Ordered_Maps is
   pragma Preelaborate;
--  pragma Remote_Types; -- it defends to define Reference_Type...

   function Equivalent_Keys (Left, Right : Key_Type) return Boolean;

   type Map is tagged private;
   pragma Preelaborable_Initialization (Map);

   type Cursor is private;
   pragma Preelaborable_Initialization (Cursor);

--  Empty_Map : constant Map;
   function Empty_Map return Map;

   No_Element : constant Cursor;

   function "=" (Left, Right : Map) return Boolean;

   function Length (Container : Map) return Count_Type;

   function Is_Empty (Container : Map) return Boolean;

   procedure Clear (Container : in out Map);

   function Key (Position : Cursor) return Key_Type;

   function Element (Position : Cursor) return Element_Type;

   procedure Replace_Element (
      Container : in out Map;
      Position : Cursor;
      New_Item : Element_Type);

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : Element_Type));

   procedure Update_Element (
      Container : in out Map;
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : in out Element_Type));

   procedure Assign (Target : in out Map; Source : Map);

   function Copy (Source : Map) return Map;

   procedure Move (Target : in out Map; Source : in out Map);

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type;
      Position : out Cursor;
      Inserted : out Boolean);

--  diff (Insert)
--
--
--
--

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Include (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Replace (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type);

   procedure Exclude (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Key : Key_Type);

   procedure Delete (Container : in out Map; Position : in out Cursor);

--  procedure Delete_First (Container : in out Map);

--  procedure Delete_Last (Container : in out Map);

   function First (Container : Map) return Cursor;

--  function First_Element (Container : Map) return Element_Type;

--  function First_Key (Container : Map) return Key_Type;

   function Last (Container : Map) return Cursor;

--  function Last_Element (Container : Map) return Element_Type;

--  function Last_Key (Container : Map) return Key_Type;

   function Next (Position : Cursor) return Cursor;

   procedure Next (Position : in out Cursor);

   function Previous (Position : Cursor) return Cursor;

   procedure Previous (Position : in out Cursor);

   function Find (Container : Map; Key : Key_Type) return Cursor;

   function Element (Container : Map; Key : Key_Type) return Element_Type;

   function Floor (Container : Map; Key : Key_Type) return Cursor;

   function Ceiling (Container : Map; Key : Key_Type) return Cursor;

   function Contains (Container : Map; Key : Key_Type) return Boolean;

   function Has_Element (Position : Cursor) return Boolean;

   function "<" (Left, Right : Cursor) return Boolean;

--  function ">" (Left, Right : Cursor) return Boolean;

--  function "<" (Left : Cursor; Right : Key_Type) return Boolean;

--  function ">" (Left : Cursor; Right : Key_Type) return Boolean;

--  function "<" (Left : Key_Type; Right : Cursor) return Boolean;

--  function ">" (Left : Key_Type; Right : Cursor) return Boolean;

   procedure Iterate (
      Container : Map;
      Process : not null access procedure (Position : Cursor));

   procedure Reverse_Iterate (
      Container : Map;
      Process : not null access procedure (Position : Cursor));

   --  AI05-0212-1
   type Constant_Reference_Type (
      Key : not null access constant Key_Type;
      Element : not null access constant Element_Type) is limited private;
   type Reference_Type (
      Key : not null access constant Key_Type;
      Element : not null access Element_Type) is limited private;
   function Constant_Reference (
      Container : not null access constant Map;
      Position : Cursor)
      return Constant_Reference_Type;
   function Constant_Reference (
      Container : not null access constant Map;
      Key : Key_Type)
      return Constant_Reference_Type;
   function Reference (
      Container : not null access Map;
      Position : Cursor)
      return Reference_Type;
   function Reference (
      Container : not null access Map;
      Key : Key_Type)
      return Reference_Type;

   --  AI05-0139-2
--  type Iterator_Type is new Reversible_Iterator with private;
   type Iterator is limited private;
   function First (Object : Iterator) return Cursor;
   function Next (Object : Iterator; Position : Cursor) return Cursor;
   function Last (Object : Iterator) return Cursor;
   function Previous (Object : Iterator; Position : Cursor) return Cursor;
   function Iterate (Container : not null access constant Map)
      return Iterator;

--  diff (Equivalents)
--
--
--
--
--

private

   package Binary_Trees renames Containers.Inside.Binary_Trees;
   package Base renames Binary_Trees.Arne_Andersson;
   package Copy_On_Write renames Containers.Inside.Copy_On_Write;

   type Key_Access is access Key_Type;
   type Element_Access is access Element_Type;

   type Node is limited record
      Super : aliased Base.Node;
      Key : Key_Access;
      Element : Element_Access;
   end record;

   --  place Super at first whether Element_Type is controlled-type
   for Node use record
      Super at 0 range 0 .. Base.Node_Size - 1;
   end record;

   type Data is limited record
      Super : aliased Copy_On_Write.Data;
      Root : Binary_Trees.Node_Access := null;
      Length : Count_Type := 0;
   end record;

   type Data_Access is access Data;

   type Map is new Finalization.Controlled with record
      Super : aliased Copy_On_Write.Container;
--  diff
   end record;

   overriding procedure Adjust (Object : in out Map);
   overriding procedure Finalize (Object : in out Map)
      renames Clear;

   package No_Primitives is
      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Map);
      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Map);
   end No_Primitives;

   for Map'Read use No_Primitives.Read;
   for Map'Write use No_Primitives.Write;

   type Cursor is access Node;

   No_Element : constant Cursor := null;

   type Constant_Reference_Type (
      Key : not null access constant Key_Type;
      Element : not null access constant Element_Type) is null record;

   type Reference_Type (
      Key : not null access constant Key_Type;
      Element : not null access Element_Type) is null record;

   type Iterator is not null access constant Map;

end Ada.Containers.Indefinite_Ordered_Maps;
