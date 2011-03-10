pragma License (Unrestricted);
--  diff (System.Arrays)
private with Ada.Finalization;
private with Ada.Streams;
private with System.Reference_Counting;
generic
   type Index_Type is range <>;
   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
package Ada.Containers.Indefinite_Vectors is
   pragma Preelaborate;
--  pragma Remote_Types; --  it defends to define Reference_Type...

   subtype Extended_Index is Index_Type'Base range
         Index_Type'First - 1 ..
         Index_Type'Min (Index_Type'Base'Last - 1, Index_Type'Last) + 1;
   No_Index : constant Extended_Index := Extended_Index'First;

   type Vector is tagged private;
   pragma Preelaborable_Initialization (Vector);

--  type Cursor is private;
--  pragma Preelaborable_Initialization (Cursor);
   subtype Cursor is Extended_Index; --  extended

--  Empty_Vector : constant Vector;
   function Empty_Vector return Vector; --  extended
--  No_Element : constant Cursor;
   No_Element : Cursor renames No_Index; -- extended

   function "=" (Left, Right : Vector) return Boolean;

   function To_Vector (Length : Count_Type) return Vector;

   function To_Vector (New_Item : Element_Type; Length : Count_Type)
      return Vector;

   function "&" (Left, Right : Vector) return Vector;

   function "&" (Left : Vector; Right : Element_Type) return Vector;

   function "&" (Left : Element_Type; Right : Vector) return Vector;

   function "&" (Left, Right : Element_Type) return Vector;

   function Capacity (Container : Vector) return Count_Type;

   procedure Reserve_Capacity (
      Container : in out Vector;
      Capacity : Count_Type);

   function Length (Container : Vector) return Count_Type;

   procedure Set_Length (Container : in out Vector; Length : Count_Type);

   function Is_Empty (Container : Vector) return Boolean;

   procedure Clear (Container : in out Vector);

   function To_Cursor (Container : Vector; Index : Extended_Index)
      return Cursor;

   function To_Index (Position : Cursor) return Extended_Index;

   function Element (Container : Vector; Index : Index_Type)
      return Element_Type;

--  function Element (Position : Cursor) return Element_Type;

   procedure Replace_Element (
      Container : in out Vector;
      Index : Index_Type;
      New_Item : Element_Type);

--  procedure Replace_Element (
--    Container : in out Vector;
--    Position : Cursor;
--    New_item : Element_Type);

   procedure Query_Element (
      Container : Vector;
      Index : Index_Type;
      Process : not null access procedure (Element : Element_Type));

--  procedure Query_Element (
--    Position : Cursor;
--    Process : not null access procedure (Element : Element_Type));

   procedure Update_Element (
      Container : in out Vector;
      Index : Index_Type;
      Process : not null access procedure (Element : in out Element_Type));

--  procedure Update_Element (
--    Container : in out Vector;
--    Position : Cursor;
--    Process : not null access procedure (Element : in out Element_Type));

   procedure Assign (Target : in out Vector; Source : Vector);

   function Copy (Source : Vector; Capacity : Count_Type := 0) return Vector;

   procedure Move (Target : in out Vector; Source : in out Vector);

   procedure Insert (
      Container : in out Vector;
      Before : Extended_Index;
      New_Item : Vector);

--  procedure Insert (
--    Container : in out Vector;
--    Before : Cursor;
--    New_Item : Vector);

   procedure Insert (
      Container : in out Vector;
      Before : Cursor;
      New_Item : Vector;
      Position : out Cursor);

   procedure Insert (
      Container : in out Vector;
      Before : Extended_Index;
      New_Item : Element_Type;
      Count : Count_Type := 1);

--  procedure Insert (
--    Container : in out Vector;
--    Before : Cursor;
--    New_Item : Element_Type;
--    Count : Count_Type := 1);

   procedure Insert (
      Container : in out Vector;
      Before : Cursor;
      New_Item : Element_Type;
      Position : out Cursor;
      Count : Count_Type := 1);

--  diff (Insert)
--
--
--

--  diff (Insert)
--
--
--
--

   procedure Prepend (Container : in out Vector; New_Item : Vector);

   procedure Prepend (
      Container : in out Vector;
      New_Item : Element_Type;
      Count : Count_Type := 1);

   procedure Append (Container : in out Vector; New_Item : Vector);

   procedure Append (
      Container : in out Vector;
      New_Item : Element_Type;
      Count : Count_Type := 1);

   procedure Insert_Space (
      Container : in out Vector;
      Before : Extended_Index;
      Count : Count_Type := 1);

   procedure Insert_Space (
      Container : in out Vector;
      Before : Cursor;
      Position : out Cursor;
      Count : Count_Type := 1);

   procedure Delete (
      Container : in out Vector;
      Index : Extended_Index;
      Count : Count_Type := 1);

--  procedure Delete (
--    Container : in out Vector;
--    Position : in out Cursor;
--    Count : Count_Type := 1);

   procedure Delete_First (Container : in out Vector; Count : Count_Type := 1);

   procedure Delete_Last (Container : in out Vector; Count : Count_Type := 1);

   procedure Reverse_Elements (Container : in out Vector);

   procedure Swap (Container : in out Vector; I, J : Index_Type);

--  procedure Swap (Container : in out Vector; I, J : Cursor);

   function First_Index (Container : Vector) return Index_Type;

   function First (Container : Vector) return Cursor;

   function First_Element (Container : Vector) return Element_Type;

   function Last_Index (Container : Vector) return Extended_Index;

   function Last (Container : Vector) return Cursor
      renames Last_Index;

   function Last_Element (Container : Vector) return Element_Type;

--  function Next (Position : Cursor) return Cursor;

--  procedure Next (Position : in out Cursor);

--  function Previous (Position : Cursor) return Cursor;

--  procedure Previous (Position : in out Cursor);

   function Find_Index (
      Container : Vector;
      Item : Element_Type;
      Index : Index_Type := Index_Type'First)
      return Extended_Index;

--  function Find (
--    Container : Vector;
--    Item : Element_Type;
--    Position : Cursor := No_Element)
--    return Cursor;
   --  substitution for Find, since No_Index is removed
   function Find (
      Container : Vector;
      Item : Element_Type)
      return Cursor;
   function Find (
      Container : Vector;
      Item : Element_Type;
      Position : Cursor) return Cursor;

   function Reverse_Find_Index (
      Container : Vector;
      Item : Element_Type;
      Index : Index_Type := Index_Type'Last)
      return Extended_Index;

--  function Reverse_Find (
--    Container : Vector;
--    Item : Element_Type;
--    Position : Cursor := No_Element)
--    return Cursor;
   --  substitution for Reverse_Find, since No_Index is removed
   function Reverse_Find (
      Container : Vector;
      Item : Element_Type) return Cursor;
   function Reverse_Find (
      Container : Vector;
      Item : Element_Type;
      Position : Cursor) return Cursor;

   function Contains (Container : Vector; Item : Element_Type) return Boolean;

   function Has_Element (Position : Cursor) return Boolean;

   procedure Iterate (
      Container : Vector;
      Process : not null access procedure (Position : Cursor));

   procedure Reverse_Iterate (
      Container : Vector;
      Process : not null access procedure (Position : Cursor));

   --  AI05-0212-1
   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is limited private;
   type Reference_Type (
      Element : not null access Element_Type) is limited private;
   function Constant_Reference (
      Container : not null access constant Vector;
      Index : Index_Type)
      return Constant_Reference_Type;
--  function Constant_Reference (
--    Container : not null access constant Vector;
--    Position : Cursor)
--    return Constant_Reference_Type;
   function Reference (
      Container : not null access Vector;
      Index : Index_Type)
      return Reference_Type;
--  function Reference (
--    Container : not null access Vector;
--    Position : Cursor)
--    return Reference_Type;

   --  AI05-0139-2
--  type Iterator_Type is new Reversible_Iterator with private;
   type Iterator is limited private;
   function First (Object : Iterator) return Cursor;
   function Next (Object : Iterator; Position : Cursor) return Cursor;
   function Last (Object : Iterator) return Cursor;
   function Previous (Object : Iterator; Position : Cursor) return Cursor;
   function Iterate (Container : not null access constant Vector)
      return Iterator;

   generic
      with function "<" (Left, Right : Element_Type) return Boolean is <>;
   package Generic_Sorting is
      function Is_Sorted (Container : Vector) return Boolean;
      procedure Sort (Container : in out Vector);
      procedure Merge (Target : in out Vector; Source : in out Vector);
   end Generic_Sorting;

--  diff (Element_Array, Slicing, Reference)
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
--
--
--
--
--

--  diff (Generic_Array_To_Vector)
--
--
--

private

   type Element_Access is access Element_Type;
   type Element_Array is array (Index_Type range <>) of Element_Access;

   type Data (Capacity_Last : Extended_Index) is limited record
      Reference_Count : aliased System.Reference_Counting.Counter;
      Max_Length : aliased Natural;
      Items : aliased Element_Array (Index_Type'First .. Capacity_Last);
   end record;

   type Data_Access is access all Data;

   Empty_Data : aliased constant Data := (
      Capacity_Last => Index_Type'First - 1,
      Reference_Count => System.Reference_Counting.Static,
      Max_Length => 0,
      Items => <>);

   type Vector is new Finalization.Controlled with record
      Data : aliased not null Data_Access := Empty_Data'Unrestricted_Access;
      Length : Count_Type := 0;
   end record;

   overriding procedure Adjust (Object : in out Vector);
   overriding procedure Finalize (Object : in out Vector)
      renames Clear;

   package No_Primitives is
      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Vector);
      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Vector);
   end No_Primitives;

   for Vector'Read use No_Primitives.Read;
   for Vector'Write use No_Primitives.Write;

   type Constant_Reference_Type (
      Element : not null access constant Element_Type) is limited null record;
   type Reference_Type (
      Element : not null access Element_Type) is limited null record;

   type Iterator is limited record
      Last_Index : Extended_Index;
   end record;

end Ada.Containers.Indefinite_Vectors;
