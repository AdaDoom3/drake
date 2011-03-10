with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Containers.Comparators;
package body Ada.Containers.Indefinite_Ordered_Maps is
   use type Binary_Trees.Node_Access;
   use type Copy_On_Write.Data_Access;

   function Upcast is new Unchecked_Conversion (
      Cursor,
      Binary_Trees.Node_Access);
   function Downcast is new Unchecked_Conversion (
      Binary_Trees.Node_Access,
      Cursor);

   function Upcast is new Unchecked_Conversion (
      Data_Access,
      Copy_On_Write.Data_Access);
   function Downcast is new Unchecked_Conversion (
      Copy_On_Write.Data_Access,
      Data_Access);

   function Compare is new Comparators.Generic_Compare (Key_Type);

   function Find (
      Data : Data_Access;
      Key : Key_Type;
      Mode : Binary_Trees.Find_Mode) return Cursor;
   function Find (
      Data : Data_Access;
      Key : Key_Type;
      Mode : Binary_Trees.Find_Mode) return Cursor
   is
      function Compare (Right : not null Binary_Trees.Node_Access)
         return Integer;
      function Compare (Right : not null Binary_Trees.Node_Access)
         return Integer is
      begin
         return Compare (Key, Downcast (Right).Key.all);
      end Compare;
   begin
      return Downcast (Binary_Trees.Find (
         Data.Root,
         Mode,
         Compare => Compare'Access));
   end Find;

   procedure Copy_Node (
      Target : out Binary_Trees.Node_Access;
      Source : not null Binary_Trees.Node_Access);
   procedure Copy_Node (
      Target : out Binary_Trees.Node_Access;
      Source : not null Binary_Trees.Node_Access)
   is
      New_Node : constant Cursor := new Node'(Super => <>,
         Key => new Key_Type'(Downcast (Source).Key.all),
         Element => new Element_Type'(Downcast (Source).Element.all));
   begin
      Target := Upcast (New_Node);
   end Copy_Node;

   procedure Free is new Unchecked_Deallocation (Key_Type, Key_Access);
   procedure Free is new Unchecked_Deallocation (Element_Type, Element_Access);
   procedure Free is new Unchecked_Deallocation (Node, Cursor);

   procedure Free_Node (Object : in out Binary_Trees.Node_Access);
   procedure Free_Node (Object : in out Binary_Trees.Node_Access) is
      X : Cursor := Downcast (Object);
   begin
      Free (X.Key);
      Free (X.Element);
      Free (X);
      Object := null;
   end Free_Node;

   procedure Allocate_Data (
      Target : out Copy_On_Write.Data_Access);
   procedure Allocate_Data (
      Target : out Copy_On_Write.Data_Access)
   is
      New_Data : constant Data_Access := new Data'(
         Super => <>,
         Root => null,
         Length => 0);
   begin
      Target := Upcast (New_Data);
   end Allocate_Data;

   procedure Copy_Data (
      Target : out Copy_On_Write.Data_Access;
      Source : not null Copy_On_Write.Data_Access;
      Capacity : Count_Type);
   procedure Copy_Data (
      Target : out Copy_On_Write.Data_Access;
      Source : not null Copy_On_Write.Data_Access;
      Capacity : Count_Type)
   is
      pragma Unreferenced (Capacity);
      New_Data : Data_Access := new Data'(
         Super => <>,
         Root => null,
         Length => 0);
   begin
      Base.Copy (
         New_Data.Root,
         New_Data.Length,
         Source => Downcast (Source).Root,
         Copy => Copy_Node'Access);
      Target := Upcast (New_Data);
   end Copy_Data;

   procedure Free is new Unchecked_Deallocation (Data, Data_Access);

   procedure Free_Data (Data : in out Copy_On_Write.Data_Access);
   procedure Free_Data (Data : in out Copy_On_Write.Data_Access) is
      X : Data_Access := Downcast (Data);
   begin
      Binary_Trees.Free (
         X.Root,
         X.Length,
         Free => Free_Node'Access);
      Free (X);
      Data := null;
   end Free_Data;

   procedure Unique (Container : in out Map; To_Update : Boolean);
   procedure Unique (Container : in out Map; To_Update : Boolean) is
   begin
      Copy_On_Write.Unique (
         Container.Super'Access,
         To_Update,
         0,
         Allocate => Allocate_Data'Access,
         Copy => Copy_Data'Access);
   end Unique;

   overriding procedure Adjust (Object : in out Map) is
   begin
      Copy_On_Write.Adjust (Object.Super'Access);
   end Adjust;

   procedure Assign (Target : in out Map; Source : Map) is
   begin
      Copy_On_Write.Assign (
         Target.Super'Access,
         Source.Super'Access,
         Free => Free_Data'Access);
   end Assign;

   function Ceiling (Container : Map; Key : Key_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Key,
            Binary_Trees.Ceiling);
      end if;
   end Ceiling;

   procedure Clear (Container : in out Map) is
   begin
      Copy_On_Write.Clear (
         Container.Super'Access,
         Free => Free_Data'Access);
   end Clear;

   function Constant_Reference (
      Container : not null access constant Map;
      Position : Cursor)
      return Constant_Reference_Type
   is
      pragma Unreferenced (Container);
   begin
      return (
         Key => Position.Key.all'Access,
         Element => Position.Element.all'Access);
   end Constant_Reference;

   function Constant_Reference (
      Container : not null access constant Map;
      Key : Key_Type)
      return Constant_Reference_Type
   is
      Position : constant not null Cursor := Find (Container.all, Key);
   begin
      return (
         Key => Position.Key.all'Access,
         Element => Position.Element.all'Access);
   end Constant_Reference;

   function Contains (Container : Map; Key : Key_Type) return Boolean is
   begin
      return Find (Container, Key) /= null;
   end Contains;

   function Copy (Source : Map) return Map is
   begin
      return (Finalization.Controlled with
         Super => Copy_On_Write.Copy (
            Source.Super'Access,
            0,
            Copy => Copy_Data'Access));
   end Copy;

   procedure Delete (Container : in out Map; Key : Key_Type) is
      Position : Cursor := Find (Container, Key);
   begin
      Delete (Container, Position);
   end Delete;

   procedure Delete (Container : in out Map; Position : in out Cursor) is
      Position_2 : Binary_Trees.Node_Access := Upcast (Position);
   begin
      Unique (Container, True);
      Base.Remove (
         Downcast (Container.Super.Data).Root,
         Downcast (Container.Super.Data).Length,
         Position_2);
      Free_Node (Position_2);
      Position := null;
   end Delete;

   function Element (Position : Cursor) return Element_Type is
   begin
      return Position.Element.all;
   end Element;

   function Element (Container : Map; Key : Key_Type) return Element_Type is
   begin
      return Find (Container, Key).Element.all;
   end Element;

   function Empty_Map return Map is
   begin
      return (Finalization.Controlled with Super => (null, null));
   end Empty_Map;

   function Equivalent_Keys (Left, Right : Key_Type) return Boolean is
   begin
      return not (Left < Right) and then not (Right < Left);
   end Equivalent_Keys;

   procedure Exclude (Container : in out Map; Key : Key_Type) is
      Position : Cursor := Find (Container, Key);
   begin
      if Position /= null then
         Delete (Container, Position);
      end if;
   end Exclude;

   function Find (Container : Map; Key : Key_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Key,
            Binary_Trees.Just);
      end if;
   end Find;

   function First (Container : Map) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Binary_Trees.First (
            Downcast (Container.Super.Data).Root));
      end if;
   end First;

   function First (Object : Iterator) return Cursor is
   begin
      return First (Object.all);
   end First;

   function Floor (Container : Map; Key : Key_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Key,
            Binary_Trees.Floor);
      end if;
   end Floor;

   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position /= No_Element;
   end Has_Element;

   procedure Include (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type)
   is
      Position : Cursor;
      Inserted : Boolean;
   begin
      Insert (Container, Key, New_Item, Position, Inserted);
      if not Inserted then
         Replace_Element (Container, Position, New_Item);
      end if;
   end Include;

--  diff (Insert)
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
--
--
--
--
--

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type;
      Position : out Cursor;
      Inserted : out Boolean)
   is
      Before : constant Cursor := Ceiling (Container, Key);
   begin
      if Before = null or else Key < Before.Key.all then
         Unique (Container, True);
         Position := new Node'(
            Super => <>,
            Key => new Key_Type'(Key),
            Element => new Element_Type'(New_Item));
         Base.Insert (
            Downcast (Container.Super.Data).Root,
            Downcast (Container.Super.Data).Length,
            Upcast (Before),
            Upcast (Position));
         Inserted := True;
      else
         Position := Before;
         Inserted := False;
      end if;
   end Insert;

   procedure Insert (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type)
   is
      Position : Cursor;
      Inserted : Boolean;
   begin
      Insert (Container, Key, New_Item, Position, Inserted);
      if not Inserted then
         raise Constraint_Error;
      end if;
   end Insert;

   function Is_Empty (Container : Map) return Boolean is
   begin
      return Container.Super.Data = null
         or else Downcast (Container.Super.Data).Root = null;
   end Is_Empty;

   procedure Iterate (
      Container : Map;
      Process : not null access procedure (Position : Cursor))
   is
      procedure Process_2 (Position : not null Binary_Trees.Node_Access);
      procedure Process_2 (Position : not null Binary_Trees.Node_Access) is
      begin
         Process (Downcast (Position));
      end Process_2;
   begin
      if not Is_Empty (Container) then
         Unique (Container'Unrestricted_Access.all, False);
         Binary_Trees.Iterate (
            Downcast (Container.Super.Data).Root,
            Process_2'Access);
      end if;
   end Iterate;

   function Iterate (Container : not null access constant Map)
      return Iterator is
   begin
      return Iterator (Container);
   end Iterate;

   function Key (Position : Cursor) return Key_Type is
   begin
      return Position.Key.all;
   end Key;

   function Last (Container : Map) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Binary_Trees.Last (
            Downcast (Container.Super.Data).Root));
      end if;
   end Last;

   function Last (Object : Iterator) return Cursor is
   begin
      return Last (Object.all);
   end Last;

   function Length (Container : Map) return Count_Type is
   begin
      if Container.Super.Data = null then
         return 0;
      else
         return Downcast (Container.Super.Data).Length;
      end if;
   end Length;

   procedure Move (Target : in out Map; Source : in out Map) is
   begin
      Copy_On_Write.Move (
         Target.Super'Access,
         Source.Super'Access,
         Free => Free_Data'Access);
--  diff
--  diff
--  diff
   end Move;

   function Next (Position : Cursor) return Cursor is
   begin
      return Downcast (Binary_Trees.Next (Upcast (Position)));
   end Next;

   procedure Next (Position : in out Cursor) is
   begin
      Position := Downcast (Binary_Trees.Next (Upcast (Position)));
   end Next;

   function Next (Object : Iterator; Position : Cursor) return Cursor is
      pragma Unreferenced (Object);
   begin
      return Next (Position);
   end Next;

   function No_Element return Cursor is
   begin
      return null;
   end No_Element;

   function Previous (Position : Cursor) return Cursor is
   begin
      return Downcast (Binary_Trees.Previous (Upcast (Position)));
   end Previous;

   procedure Previous (Position : in out Cursor) is
   begin
      Position := Downcast (Binary_Trees.Previous (Upcast (Position)));
   end Previous;

   function Previous (Object : Iterator; Position : Cursor) return Cursor is
      pragma Unreferenced (Object);
   begin
      return Previous (Position);
   end Previous;

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : Element_Type)) is
   begin
      Process (Position.Key.all, Position.Element.all);
   end Query_Element;

   function Reference (
      Container : not null access Map;
      Position : Cursor)
      return Reference_Type is
   begin
      Unique (Container.all, True);
--  diff
      return (
         Key => Position.Key.all'Access,
         Element => Position.Element.all'Access);
   end Reference;

   function Reference (
      Container : not null access Map;
      Key : Key_Type)
      return Reference_Type
   is
      Position : constant not null Cursor := Find (Container.all, Key);
   begin
      Unique (Container.all, True);
      return (
         Key => Position.Key.all'Access,
         Element => Position.Element.all'Access);
   end Reference;

   procedure Replace (
      Container : in out Map;
      Key : Key_Type;
      New_Item : Element_Type) is
   begin
      Replace_Element (Container, Find (Container, Key), New_Item);
   end Replace;

   procedure Replace_Element (
      Container : in out Map;
      Position : Cursor;
      New_Item : Element_Type) is
   begin
      Unique (Container, True);
      Free (Position.Element);
      Position.Element := new Element_Type'(New_Item);
   end Replace_Element;

   procedure Reverse_Iterate (
      Container : Map;
      Process : not null access procedure (Position : Cursor))
   is
      procedure Process_2 (Position : not null Binary_Trees.Node_Access);
      procedure Process_2 (Position : not null Binary_Trees.Node_Access) is
      begin
         Process (Downcast (Position));
      end Process_2;
   begin
      if not Is_Empty (Container) then
         Unique (Container'Unrestricted_Access.all, False);
         Binary_Trees.Reverse_Iterate (
            Downcast (Container.Super.Data).Root,
            Process_2'Access);
      end if;
   end Reverse_Iterate;

   procedure Update_Element (
      Container : in out Map;
      Position : Cursor;
      Process : not null access procedure (
         Key : Key_Type;
         Element : in out Element_Type)) is
   begin
      Unique (Container, True);
--  diff
      Process (Position.Key.all, Position.Element.all);
   end Update_Element;

   function "=" (Left, Right : Map) return Boolean is
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean;
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean is
      begin
         return Equivalent_Keys (
            Downcast (Left).Key.all,
            Downcast (Right).Key.all)
            and then Downcast (Left).Element.all =
               Downcast (Right).Element.all;
      end Equivalent;
   begin
      if Is_Empty (Left) then
         return Is_Empty (Right);
      elsif Left.Super.Data = Right.Super.Data then
         return True;
      elsif Length (Left) = Length (Right) then
         Unique (Left'Unrestricted_Access.all, False);
         Unique (Right'Unrestricted_Access.all, False);
         return Binary_Trees.Equivalent (
            Downcast (Left.Super.Data).Root,
            Downcast (Right.Super.Data).Root,
            Equivalent'Access);
      else
         return False;
      end if;
   end "=";

   function "<" (Left, Right : Cursor) return Boolean is
   begin
      return Left.Key.all < Right.Key.all;
   end "<";

   package body No_Primitives is

      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Map)
      is
         Length : Count_Type'Base;
      begin
         Count_Type'Read (Stream, Length);
         Clear (Container);
         for I in 1 .. Length loop
            declare
               Key : constant Key_Type := Key_Type'Input (Stream);
               Element : constant Element_Type := Element_Type'Input (Stream);
            begin
--  diff
--  diff
               Include (Container, Key, Element);
            end;
         end loop;
      end Read;

      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Map)
      is
         procedure Process (Position : Cursor);
         procedure Process (Position : Cursor) is
         begin
            Key_Type'Output (Stream, Position.Key.all);
            Element_Type'Output (Stream, Position.Element.all);
         end Process;
      begin
         Count_Type'Write (Stream, Container.Length);
         Iterate (Container, Process'Access);
      end Write;

   end No_Primitives;

end Ada.Containers.Indefinite_Ordered_Maps;
