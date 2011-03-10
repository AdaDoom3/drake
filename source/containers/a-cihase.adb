with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
package body Ada.Containers.Indefinite_Hashed_Sets is
   use type Hash_Tables.Table_Access;
   use type Copy_On_Write.Data_Access;

   function Upcast is new Unchecked_Conversion (
      Cursor,
      Hash_Tables.Node_Access);
   function Downcast is new Unchecked_Conversion (
      Hash_Tables.Node_Access,
      Cursor);

   function Upcast is new Unchecked_Conversion (
      Data_Access,
      Copy_On_Write.Data_Access);
   function Downcast is new Unchecked_Conversion (
      Copy_On_Write.Data_Access,
      Data_Access);

   function Equivalent_Node (Left, Right : not null Hash_Tables.Node_Access)
      return Boolean;
   function Equivalent_Node (Left, Right : not null Hash_Tables.Node_Access)
      return Boolean is
   begin
      return Equivalent_Elements (
         Downcast (Left).Element.all,
         Downcast (Right).Element.all);
   end Equivalent_Node;

   function Find (Data : Data_Access; Hash : Hash_Type; Item : Element_Type)
      return Cursor;
   function Find (Data : Data_Access; Hash : Hash_Type; Item : Element_Type)
      return Cursor
   is
      function Equivalent (Position : not null Hash_Tables.Node_Access)
         return Boolean;
      function Equivalent (Position : not null Hash_Tables.Node_Access)
         return Boolean is
      begin
         return Equivalent_Elements (Downcast (Position).Element.all, Item);
      end Equivalent;
   begin
      return Downcast (Hash_Tables.Find (
         Data.Table,
         Hash,
         Equivalent => Equivalent'Access));
   end Find;

   procedure Copy_Node (
      Target : out Hash_Tables.Node_Access;
      Source : not null Hash_Tables.Node_Access);
   procedure Copy_Node (
      Target : out Hash_Tables.Node_Access;
      Source : not null Hash_Tables.Node_Access)
   is
      New_Node : constant Cursor := new Node'(Super => <>,
         Element => new Element_Type'(Downcast (Source).Element.all));
   begin
      Target := Upcast (New_Node);
   end Copy_Node;

   procedure Free is new Unchecked_Deallocation (Element_Type, Element_Access);
   procedure Free is new Unchecked_Deallocation (Node, Cursor);

   procedure Free_Node (Object : in out Hash_Tables.Node_Access);
   procedure Free_Node (Object : in out Hash_Tables.Node_Access) is
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
         Table => null,
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
      New_Data : Data_Access := new Data'(
         Super => <>,
         Table => null,
         Length => 0);
   begin
      Hash_Tables.Copy (
         New_Data.Table,
         New_Data.Length,
         Downcast (Source).Table,
         Capacity,
         Copy => Copy_Node'Access);
      Target := Upcast (New_Data);
   end Copy_Data;

   procedure Free is new Unchecked_Deallocation (Data, Data_Access);

   procedure Free_Data (Data : in out Copy_On_Write.Data_Access);
   procedure Free_Data (Data : in out Copy_On_Write.Data_Access) is
      X : Data_Access := Downcast (Data);
   begin
      Hash_Tables.Free (
         X.Table,
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
         Capacity (Container),
         Allocate => Allocate_Data'Access,
         Copy => Copy_Data'Access);
   end Unique;

   function Find (Container : Set; Hash : Hash_Type; Item : Element_Type)
      return Cursor;
   function Find (Container : Set; Hash : Hash_Type; Item : Element_Type)
      return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Find (
            Downcast (Container.Super.Data),
            Hash,
            Item);
      end if;
   end Find;

   procedure Adjust (Object : in out Set) is
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

   function Capacity (Container : Set) return Count_Type is
   begin
      if Container.Super.Data = null then
         return 0;
      else
         return Hash_Tables.Capacity (
            Downcast (Container.Super.Data).Table);
      end if;
   end Capacity;

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
      return (Element => Position.Element);
   end Constant_Reference;

   function Contains (Container : Set; Item : Element_Type) return Boolean is
   begin
      return Find (Container, Item) /= null;
   end Contains;

   function Copy (Source : Set; Capacity : Count_Type := 0) return Set is
   begin
      return (Finalization.Controlled with Super => Copy_On_Write.Copy (
         Source.Super'Access,
         Count_Type'Max (Capacity, Length (Source)),
         Copy => Copy_Data'Access));
   end Copy;

   procedure Delete (Container : in out Set; Item : Element_Type) is
      Position : Cursor := Find (Container, Item);
   begin
      Delete (Container, Position);
   end Delete;

   procedure Delete (Container : in out Set; Position : in out Cursor) is
   begin
      Unique (Container, True);
      Hash_Tables.Remove (
         Downcast (Container.Super.Data).Table,
         Downcast (Container.Super.Data).Length,
         Upcast (Position));
      Free (Position);
   end Delete;

   procedure Difference (Target : in out Set; Source : Set) is
   begin
      if not Is_Empty (Target) and then not Is_Empty (Source) then
         Unique (Target, True);
         Hash_Tables.Merge (
            Downcast (Target.Super.Data).Table,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Table,
            Downcast (Source.Super.Data).Length,
            In_Only_Left => True,
            In_Only_Right => False,
            In_Both => False,
            Equivalent => Equivalent_Node'Access,
            Copy => Copy_Node'Access,
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
            Hash_Tables.Merge (
               Downcast (Result.Super.Data).Table,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Table,
               Downcast (Left.Super.Data).Length,
               Downcast (Right.Super.Data).Table,
               Downcast (Right.Super.Data).Length,
               In_Only_Left => True,
               In_Only_Right => False,
               In_Both => False,
               Equivalent => Equivalent_Node'Access,
               Copy => Copy_Node'Access);
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

   function Equivalent_Elements (Left : Cursor; Right : Element_Type)
      return Boolean is
   begin
      return Equivalent_Elements (Left.Element.all, Right);
   end Equivalent_Elements;

   function Equivalent_Sets (Left, Right : Set) return Boolean is
   begin
      if Is_Empty (Left) then
         return Is_Empty (Right);
      elsif Is_Empty (Right) then
         return False;
      elsif Left.Super.Data = Right.Super.Data then
         return True;
      else
         return Hash_Tables.Equivalent (
            Downcast (Left.Super.Data).Table,
            Downcast (Left.Super.Data).Length,
            Downcast (Right.Super.Data).Table,
            Downcast (Right.Super.Data).Length,
            Equivalent => Equivalent_Node'Access);
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
      return Find (Container, Hash (Item), Item);
   end Find;

   function First (Container : Set) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Hash_Tables.First (
            Downcast (Container.Super.Data).Table));
      end if;
   end First;

--  diff (Generic_Array_To_Set)
--
--
--
--
--
--
--
--

   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position /= null;
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
      New_Hash : constant Hash_Type := Hash (New_Item);
   begin
      Position := Find (Container, New_Hash, New_Item);
      Inserted := Position = null;
      if Inserted then
         Unique (Container, True);
         Position := new Node'(
            Super => <>,
            Element => new Element_Type'(New_Item));
         Hash_Tables.Insert (
            Downcast (Container.Super.Data).Table,
            Downcast (Container.Super.Data).Length,
            New_Hash,
            Upcast (Position));
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
         Hash_Tables.Merge (
            Downcast (Target.Super.Data).Table,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Table,
            Downcast (Source.Super.Data).Length,
            In_Only_Left => False,
            In_Only_Right => False,
            In_Both => True,
            Equivalent => Equivalent_Node'Access,
            Copy => Copy_Node'Access,
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
            Hash_Tables.Merge (
               Downcast (Result.Super.Data).Table,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Table,
               Downcast (Left.Super.Data).Length,
               Downcast (Right.Super.Data).Table,
               Downcast (Right.Super.Data).Length,
               In_Only_Left => False,
               In_Only_Right => False,
               In_Both => True,
               Equivalent => Equivalent_Node'Access,
               Copy => Copy_Node'Access);
         end return;
      end if;
   end Intersection;

   function Is_Empty (Container : Set) return Boolean is
   begin
      return Container.Super.Data = null
         or else Downcast (Container.Super.Data).Length = 0;
   end Is_Empty;

   function Is_Subset (Subset : Set; Of_Set : Set) return Boolean is
   begin
      if Is_Empty (Subset) then
         return True;
      elsif Is_Empty (Of_Set) then
         return False;
      else
         return Hash_Tables.Is_Subset (
            Downcast (Subset.Super.Data).Table,
            Downcast (Of_Set.Super.Data).Table,
            Equivalent => Equivalent_Node'Access);
      end if;
   end Is_Subset;

   procedure Iterate (
      Container : Set;
      Process : not null access procedure (Position : Cursor))
   is
      procedure Process_2 (Position : not null Hash_Tables.Node_Access);
      procedure Process_2 (Position : not null Hash_Tables.Node_Access) is
      begin
         Process (Downcast (Position));
      end Process_2;
   begin
      if not Is_Empty (Container) then
         Unique (Container'Unrestricted_Access.all, False);
         Hash_Tables.Iterate (
            Downcast (Container.Super.Data).Table,
            Process_2'Access);
      end if;
   end Iterate;

   function Last (Container : Set) return Cursor is
   begin
      if Is_Empty (Container) then
         return null;
      else
         Unique (Container'Unrestricted_Access.all, False);
         return Downcast (Hash_Tables.Last (
            Downcast (Container.Super.Data).Table));
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
   end Move;

   function Next (Position : Cursor) return Cursor is
   begin
      return Downcast (Position.Super.Next);
   end Next;

   procedure Next (Position : in out Cursor) is
   begin
      Position := Downcast (Position.Super.Next);
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
         return Hash_Tables.Overlap (
            Downcast (Left.Super.Data).Table,
            Downcast (Right.Super.Data).Table,
            Equivalent => Equivalent_Node'Access);
      end if;
   end Overlap;

   procedure Query_Element (
      Position : Cursor;
      Process : not null access procedure (Element : Element_Type)) is
   begin
      Process (Position.Element.all);
   end Query_Element;

   function Reference (Container : not null access Set; Position : Cursor)
      return Reference_Type is
   begin
      Unique (Container.all, True);
--  diff
      return (Element => Position.Element);
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

   procedure Reserve_Capacity (
      Container : in out Set;
      Capacity : Count_Type)
   is
      New_Capacity : constant Count_Type :=
         Count_Type'Max (Capacity, Length (Container));
   begin
      Copy_On_Write.Unique (
         Container.Super'Access,
         True,
         New_Capacity,
         Allocate => Allocate_Data'Access,
         Copy => Copy_Data'Access);
      Hash_Tables.Rebuild (
         Downcast (Container.Super.Data).Table,
         New_Capacity);
   end Reserve_Capacity;

   procedure Symmetric_Difference (Target : in out Set; Source : Set) is
   begin
      if not Is_Empty (Source) then
         Unique (Target, True);
         Hash_Tables.Merge (
            Downcast (Target.Super.Data).Table,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Table,
            Downcast (Source.Super.Data).Length,
            In_Only_Left => True,
            In_Only_Right => True,
            In_Both => False,
            Equivalent => Equivalent_Node'Access,
            Copy => Copy_Node'Access,
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
            Hash_Tables.Merge (
               Downcast (Result.Super.Data).Table,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Table,
               Downcast (Left.Super.Data).Length,
               Downcast (Right.Super.Data).Table,
               Downcast (Right.Super.Data).Length,
               In_Only_Left => True,
               In_Only_Right => True,
               In_Both => False,
               Equivalent => Equivalent_Node'Access,
               Copy => Copy_Node'Access);
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
         Hash_Tables.Merge (
            Downcast (Target.Super.Data).Table,
            Downcast (Target.Super.Data).Length,
            Downcast (Source.Super.Data).Table,
            Downcast (Source.Super.Data).Length,
            In_Only_Left => True,
            In_Only_Right => True,
            In_Both => True,
            Equivalent => Equivalent_Node'Access,
            Copy => Copy_Node'Access,
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
            Hash_Tables.Merge (
               Downcast (Result.Super.Data).Table,
               Downcast (Result.Super.Data).Length,
               Downcast (Left.Super.Data).Table,
               Downcast (Left.Super.Data).Length,
               Downcast (Right.Super.Data).Table,
               Downcast (Right.Super.Data).Length,
               In_Only_Left => True,
               In_Only_Right => True,
               In_Both => True,
               Equivalent => Equivalent_Node'Access,
               Copy => Copy_Node'Access);
         end return;
      end if;
   end Union;

   function "=" (Left, Right : Set) return Boolean is
      function Equivalent (Left, Right : not null Hash_Tables.Node_Access)
         return Boolean;
      function Equivalent (Left, Right : not null Hash_Tables.Node_Access)
         return Boolean is
      begin
         return Downcast (Left).Element.all = Downcast (Right).Element.all;
      end Equivalent;
   begin
      if Is_Empty (Left) then
         return Is_Empty (Right);
      elsif Is_Empty (Right) then
         return False;
      elsif Left.Super.Data = Right.Super.Data then
         return True;
      else
         return Hash_Tables.Equivalent (
            Downcast (Left.Super.Data).Table,
            Downcast (Left.Super.Data).Length,
            Downcast (Right.Super.Data).Table,
            Downcast (Right.Super.Data).Length,
            Equivalent => Equivalent'Access);
      end if;
   end "=";

   function "<=" (Left, Right : Cursor) return Boolean is
   begin
      return Left /= null and then
         not Hash_Tables.Is_Before (Upcast (Right), Upcast (Left));
   end "<=";

   package body Generic_Keys is

      function Contains (Container : Set; Key : Key_Type) return Boolean is
      begin
         return Find (Container, Key) /= null;
      end Contains;

      function Element (Container : Set; Key : Key_Type) return Element_Type is
      begin
         return Find (Container, Key).Element.all;
      end Element;

      procedure Exclude (Container : in out Set; Key : Key_Type) is
         Position : Cursor := Find (Container, Key);
      begin
         if Position /= null then
            Delete (Container, Position);
         end if;
      end Exclude;

      function Find (Container : Set; Key : Key_Type) return Cursor is
         function Equivalent (Position : not null Hash_Tables.Node_Access)
            return Boolean;
         function Equivalent (Position : not null Hash_Tables.Node_Access)
            return Boolean is
         begin
            return Equivalent_Keys (
               Generic_Keys.Key (Downcast (Position).Element.all), Key);
         end Equivalent;
      begin
         if Is_Empty (Container) then
            return null;
         else
            Unique (Container'Unrestricted_Access.all, False);
            return Downcast (Hash_Tables.Find (
               Downcast (Container.Super.Data).Table,
               Hash (Key),
               Equivalent => Equivalent'Access));
         end if;
      end Find;

      procedure Delete (Container : in out Set; Key : Key_Type) is
         Position : Cursor := Find (Container, Key);
      begin
         Delete (Container, Position);
      end Delete;

      function Key (Position : Cursor) return Key_Type is
      begin
         return Key (Position.Element.all);
      end Key;

      procedure Replace (
         Container : in out Set;
         Key : Key_Type;
         New_Item : Element_Type) is
      begin
         Replace_Element (Container, Find (Container, Key), New_Item);
      end Replace;

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
         for I in 1 .. Length loop
            declare
               Position : constant Cursor := new Node'(
                  Super => <>,
                  Element => new Element_Type'(Element_Type'Input (Stream)));
            begin
               Hash_Tables.Insert (
                  Downcast (Container.Super.Data).Table,
                  Downcast (Container.Super.Data).Length,
                  Hash (Position.Element.all),
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
            Element_Type'Write (Stream, Position.Element.all);
         end Process;
      begin
         Count_Type'Write (Stream, Container.Length);
         Iterate (Container, Process'Access);
      end Write;

   end No_Primitives;

end Ada.Containers.Indefinite_Hashed_Sets;