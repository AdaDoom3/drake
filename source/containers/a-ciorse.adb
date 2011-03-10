with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Containers.Comparators;
package body Ada.Containers.Indefinite_Ordered_Sets is
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

   function Compare is new Comparators.Generic_Compare (Element_Type);

   function Compare_Node (Left, Right : not null Binary_Trees.Node_Access)
      return Integer;
   function Compare_Node (Left, Right : not null Binary_Trees.Node_Access)
      return Integer is
   begin
      return Compare (
         Downcast (Left).Element.all,
         Downcast (Right).Element.all);
   end Compare_Node;

   function Find (
      Data : Data_Access;
      Item : Element_Type;
      Mode : Binary_Trees.Find_Mode)
      return Cursor;
   function Find (
      Data : Data_Access;
      Item : Element_Type;
      Mode : Binary_Trees.Find_Mode)
      return Cursor
   is
      function Compare (Right : not null Binary_Trees.Node_Access)
         return Integer;
      function Compare (Right : not null Binary_Trees.Node_Access)
         return Integer is
      begin
         return Compare (Item, Downcast (Right).Element.all);
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
         Element => new Element_Type'(Downcast (Source).Element.all));
   begin
      Target := Upcast (New_Node);
   end Copy_Node;

   procedure Free is new Unchecked_Deallocation (Element_Type, Element_Access);
   procedure Free is new Unchecked_Deallocation (Node, Cursor);

   procedure Free_Node (Object : in out Binary_Trees.Node_Access);
   procedure Free_Node (Object : in out Binary_Trees.Node_Access) is
      X : Cursor := Downcast (Object);
   begin
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

   procedure Unique (Container : in out Set; To_Update : Boolean);
   procedure Unique (Container : in out Set; To_Update : Boolean) is
   begin
      Copy_On_Write.Unique (
         Container.Super'Access,
         To_Update,
         0,
         Allocate => Allocate_Data'Access,
         Copy => Copy_Data'Access);
   end Unique;

   overriding procedure Adjust (Object : in out Set) is
   begin
      Copy_On_Write.Adjust (Object.Super'Access);
   end Adjust;

   procedure Assign (Target : in out Set; Source : Set) is
   begin
      Copy_On_Write.Assign (
         Target.Super'Access,
         Source.Super'Access,
         Free => Free_Data'Access);
   end Assign;

   function Ceiling (Container : Set; Item : Element_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Item,
            Binary_Trees.Ceiling);
      end if;
   end Ceiling;

   procedure Clear (Container : in out Set) is
   begin
      Copy_On_Write.Clear (
         Container.Super'Access,
         Free => Free_Data'Access);
   end Clear;

   function Constant_Reference (
      Container : not null access constant Set;
      Position : Cursor)
      return Constant_Reference_Type
   is
      pragma Unreferenced (Container);
   begin
      return (Element => Position.Element.all'Access);
   end Constant_Reference;

   function Contains (Container : Set; Item : Element_Type) return Boolean is
   begin
      return Find (Container, Item) /= null;
   end Contains;

   function Copy (Source : Set) return Set is
   begin
      return (Finalization.Controlled with
         Super => Copy_On_Write.Copy (
            Source.Super'Access,
            0,
            Copy => Copy_Data'Access));
   end Copy;

   procedure Delete (Container : in out Set; Item : Element_Type) is
      Position : Cursor := Find (Container, Item);
   begin
      Delete (Container, Position);
   end Delete;

   procedure Delete (Container : in out Set; Position  : in out Cursor) is
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

   procedure Difference (Target : in out Set; Source : Set) is
   begin
      if not Is_Empty (Target) and then not Is_Empty (Source) then
         Unique (Target, True);
         Binary_Trees.Merge (
            Downcast (Target.Super.Data).Root,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Root,
            In_Only_Left => True,
            In_Only_Right => False,
            In_Both => False,
            Compare => Compare_Node'Access,
            Copy => Copy_Node'Access,
            Insert => Base.Insert'Access,
            Remove => Base.Remove'Access,
            Free => Free_Node'Access);
      end if;
   end Difference;

   function Difference (Left, Right : Set) return Set is
   begin
      if Is_Empty (Left) or else Is_Empty (Right) then
         return Left;
      else
         return Result : Set do
            Unique (Result, True);
            Binary_Trees.Merge (
               Downcast (Result.Super.Data).Root,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Root,
               Downcast (Right.Super.Data).Root,
               In_Only_Left => True,
               In_Only_Right => False,
               In_Both => False,
               Compare => Compare_Node'Access,
               Copy => Copy_Node'Access,
               Insert => Base.Insert'Access);
         end return;
      end if;
   end Difference;

   function Element (Position : Cursor) return Element_Type is
   begin
      return Position.Element.all;
   end Element;

   function Empty_Set return Set is
   begin
      return (Finalization.Controlled with Super => (null, null));
   end Empty_Set;

   function Equivalent_Elements (Left, Right : Element_Type) return Boolean is
   begin
      return not (Left < Right) and then not (Right < Left);
   end Equivalent_Elements;

   function Equivalent_Sets (Left, Right : Set) return Boolean is
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean;
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean is
      begin
         return Equivalent_Elements (
            Downcast (Left).Element.all,
            Downcast (Right).Element.all);
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
   end Equivalent_Sets;

   procedure Exclude (Container : in out Set; Item : Element_Type) is
      Position : Cursor := Find (Container, Item);
   begin
      if Position /= null then
         Delete (Container, Position);
      end if;
   end Exclude;

   function Find (Container : Set; Item : Element_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Item,
            Binary_Trees.Just);
      end if;
   end Find;

   function First (Container : Set) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Binary_Trees.First (
            Downcast (Container.Super.Data).Root));
      end if;
   end First;

   function Floor (Container : Set; Item : Element_Type) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Item,
            Binary_Trees.Floor);
      end if;
   end Floor;

--  diff (Generic_Array_To_Set)
--
--
--
--
--
--
--

   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position /= No_Element;
   end Has_Element;

   procedure Include (Container : in out Set; New_Item : Element_Type) is
      Position : Cursor;
      Inserted : Boolean;
   begin
      Insert (Container, New_Item, Position, Inserted);
      if not Inserted then
         Replace_Element (Container, Position, New_Item);
      end if;
   end Include;

   procedure Insert (
      Container : in out Set;
      New_Item : Element_Type;
      Position : out Cursor;
      Inserted : out Boolean)
   is
      Before : constant Cursor := Ceiling (Container, New_Item);
   begin
      if Before = null or else New_Item < Before.Element.all then
         Unique (Container, True);
         Position := new Node'(
            Super => <>,
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

   procedure Insert (Container : in out Set; New_Item : Element_Type) is
      Position : Cursor;
      Inserted : Boolean;
   begin
      Insert (Container, New_Item, Position, Inserted);
      if not Inserted then
         raise Constraint_Error;
      end if;
   end Insert;

   procedure Intersection (Target : in out Set; Source : Set) is
   begin
      if Is_Empty (Source) then
         Clear (Target);
      else
         Unique (Target, True);
         Binary_Trees.Merge (
            Downcast (Target.Super.Data).Root,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Root,
            In_Only_Left => False,
            In_Only_Right => False,
            In_Both => True,
            Compare => Compare_Node'Access,
            Copy => Copy_Node'Access,
            Insert => Base.Insert'Access,
            Remove => Base.Remove'Access,
            Free => Free_Node'Access);
      end if;
   end Intersection;

   function Intersection (Left, Right : Set) return Set is
   begin
      if Is_Empty (Left) or else Is_Empty (Right) then
         return Empty_Set;
      else
         return Result : Set do
            Unique (Result, True);
            Binary_Trees.Merge (
               Downcast (Result.Super.Data).Root,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Root,
               Downcast (Right.Super.Data).Root,
               In_Only_Left => False,
               In_Only_Right => False,
               In_Both => True,
               Compare => Compare_Node'Access,
               Copy => Copy_Node'Access,
               Insert => Base.Insert'Access);
         end return;
      end if;
   end Intersection;

   function Is_Empty (Container : Set) return Boolean is
   begin
      return Container.Super.Data = null
         or else Downcast (Container.Super.Data).Root = null;
   end Is_Empty;

   function Is_Subset (Subset : Set; Of_Set : Set) return Boolean is
   begin
      if Is_Empty (Subset) then
         return True;
      elsif Is_Empty (Of_Set) then
         return False;
      else
         return Binary_Trees.Is_Subset (
            Downcast (Subset.Super.Data).Root,
            Downcast (Of_Set.Super.Data).Root,
            Compare => Compare_Node'Access);
      end if;
   end Is_Subset;

   procedure Iterate (
      Container : Set;
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

   function Last (Container : Set) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Binary_Trees.Last (
            Downcast (Container.Super.Data).Root));
      end if;
   end Last;

   function Length (Container : Set) return Count_Type is
   begin
      if Container.Super.Data = null then
         return 0;
      else
         return Downcast (Container.Super.Data).Length;
      end if;
   end Length;

   procedure Move (Target : in out Set; Source : in out Set) is
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

   function No_Element return Cursor is
   begin
      return null;
   end No_Element;

   function Overlap (Left, Right : Set) return Boolean is
   begin
      if Is_Empty (Left) or Is_Empty (Right) then
         return False;
      else
         return Binary_Trees.Overlap (
            Downcast (Left.Super.Data).Root,
            Downcast (Right.Super.Data).Root,
            Compare => Compare_Node'Access);
      end if;
   end Overlap;

   function Previous (Position : Cursor) return Cursor is
   begin
      return Downcast (Binary_Trees.Previous (Upcast (Position)));
   end Previous;

   procedure Previous (Position : in out Cursor) is
   begin
      Position := Downcast (Binary_Trees.Previous (Upcast (Position)));
   end Previous;

   procedure Query_Element (
      Position : Cursor;
      Process  : not null access procedure (Element : Element_Type)) is
   begin
      Process (Position.Element.all);
   end Query_Element;

   function Reference (
      Container : not null access Set;
      Position : Cursor)
      return Reference_Type is
   begin
      Unique (Container.all, True);
--  diff
      return (Element => Position.Element.all'Access);
   end Reference;

   procedure Replace (Container : in out Set; New_Item : Element_Type) is
   begin
      Replace_Element (Container, Find (Container, New_Item), New_Item);
   end Replace;

   procedure Replace_Element (
      Container : in out Set;
      Position : Cursor;
      New_Item : Element_Type) is
   begin
      Unique (Container, True);
      Free (Position.Element);
      Position.Element := new Element_Type'(New_Item);
   end Replace_Element;

   procedure Reverse_Iterate (
      Container : Set;
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

   procedure Symmetric_Difference (Target : in out Set; Source : Set) is
   begin
      if not Is_Empty (Source) then
         Unique (Target, True);
         Binary_Trees.Merge (
            Downcast (Target.Super.Data).Root,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Root,
            In_Only_Left => True,
            In_Only_Right => True,
            In_Both => False,
            Compare => Compare_Node'Access,
            Copy => Copy_Node'Access,
            Insert => Base.Insert'Access,
            Remove => Base.Remove'Access,
            Free => Free_Node'Access);
      end if;
   end Symmetric_Difference;

   function Symmetric_Difference (Left, Right : Set) return Set is
   begin
      if Is_Empty (Left) then
         return Right;
      elsif Is_Empty (Right) then
         return Left;
      else
         return Result : Set do
            Unique (Result, True);
            Binary_Trees.Merge (
               Downcast (Result.Super.Data).Root,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Root,
               Downcast (Right.Super.Data).Root,
               In_Only_Left => True,
               In_Only_Right => True,
               In_Both => False,
               Compare => Compare_Node'Access,
               Copy => Copy_Node'Access,
               Insert => Base.Insert'Access);
         end return;
      end if;
   end Symmetric_Difference;

   function To_Set (New_Item : Element_Type) return Set is
   begin
      return Result : Set do
         Insert (Result, New_Item);
      end return;
   end To_Set;

   procedure Union (Target : in out Set; Source : Set) is
   begin
      if not Is_Empty (Source) then
         Unique (Target, True);
         Binary_Trees.Merge (
            Downcast (Target.Super.Data).Root,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Root,
            In_Only_Left => True,
            In_Only_Right => True,
            In_Both => True,
            Compare => Compare_Node'Access,
            Copy => Copy_Node'Access,
            Insert => Base.Insert'Access,
            Remove => Base.Remove'Access,
            Free => Free_Node'Access);
      end if;
   end Union;

   function Union (Left, Right : Set) return Set is
   begin
      if Is_Empty (Left) then
         return Right;
      elsif Is_Empty (Right) then
         return Left;
      else
         return Result : Set do
            Unique (Result, True);
            Binary_Trees.Merge (
               Downcast (Result.Super.Data).Root,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Root,
               Downcast (Right.Super.Data).Root,
               In_Only_Left => True,
               In_Only_Right => True,
               In_Both => True,
               Compare => Compare_Node'Access,
               Copy => Copy_Node'Access,
               Insert => Base.Insert'Access);
         end return;
      end if;
   end Union;

   function "=" (Left, Right : Set) return Boolean is
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean;
      function Equivalent (Left, Right : not null Binary_Trees.Node_Access)
         return Boolean is
      begin
         return Downcast (Left).Element.all = Downcast (Right).Element.all;
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
      return Left.Element.all < Right.Element.all;
   end "<";

   function "<=" (Left, Right : Cursor) return Boolean is
   begin
      return Left /= null and then not (Right.Element.all < Left.Element.all);
   end "<=";

   function ">=" (Left, Right : Cursor) return Boolean is
   begin
      return Left /= null and then not (Left.Element.all < Right.Element.all);
   end ">=";

   package body Generic_Keys is

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
            return Compare (
               Key,
               Generic_Keys.Key (Downcast (Right).Element.all));
         end Compare;
      begin
         return Downcast (Binary_Trees.Find (
            Data.Root,
            Mode,
            Compare => Compare'Access));
      end Find;

      function Ceiling (Container : Set; Key : Key_Type) return Cursor is
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

      function Contains (Container : Set; Key : Key_Type) return Boolean is
      begin
         return Find (Container, Key) /= null;
      end Contains;

      procedure Delete (Container : in out Set; Key : Key_Type) is
         Position : Cursor := Find (Container, Key);
      begin
         Delete (Container, Position);
      end Delete;

      function Element (Container : Set; Key : Key_Type) return Element_Type is
      begin
         return Find (Container, Key).Element.all;
      end Element;

      function Equivalent_Keys (Left, Right : Key_Type) return Boolean is
      begin
         return not (Left < Right) and not (Right < Left);
      end Equivalent_Keys;

      procedure Exclude (Container : in out Set; Key : Key_Type) is
         Position : Cursor := Find (Container, Key);
      begin
         if Position /= null then
            Delete (Container, Position);
         end if;
      end Exclude;

      function Find (Container : Set; Key : Key_Type) return Cursor is
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

      function Floor (Container : Set; Key : Key_Type) return Cursor is
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

      procedure Replace (
         Container : in out Set;
         Key : Key_Type;
         New_Item : Element_Type) is
      begin
         Find (Container, Key).Element.all := New_Item;
      end Replace;

      function Key (Position : Cursor) return Key_Type is
      begin
         return Key (Position.Element.all);
      end Key;

      procedure Update_Element_Preserving_Key (
         Container : in out Set;
         Position : Cursor;
         Process : not null access procedure (Element : in out Element_Type))
         is
      begin
         Unique (Container, True);
         Process (Position.Element.all);
      end Update_Element_Preserving_Key;

   end Generic_Keys;

   package body No_Primitives is

      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Set)
      is
         Length : Count_Type'Base;
      begin
         Count_Type'Read (Stream, Length);
         Clear (Container);
         Unique (Container, True);
         for I in 1 .. Length loop
            declare
               Position : constant Cursor := new Node'(
                  Super => <>,
                  Element => new Element_Type'(Element_Type'Input (Stream)));
            begin
               Base.Insert (
                  Downcast (Container.Super.Data).Root,
                  Downcast (Container.Super.Data).Length,
                  Before => null,
                  New_Item => Upcast (Position));
            end;
         end loop;
      end Read;

      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Set)
      is
         procedure Process (Position : Cursor);
         procedure Process (Position : Cursor) is
         begin
            Element_Type'Output (Stream, Position.Element.all);
         end Process;
      begin
         Count_Type'Write (Stream, Container.Length);
         Iterate (Container, Process'Access);
      end Write;

   end No_Primitives;

end Ada.Containers.Indefinite_Ordered_Sets;