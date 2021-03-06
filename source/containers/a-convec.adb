with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Containers.Inside.Array_Sorting;
with System.Address_To_Named_Access_Conversions;
package body Ada.Containers.Vectors is
   use type Copy_On_Write.Data_Access;

   package Data_Cast is
      new System.Address_To_Named_Access_Conversions (Data, Data_Access);

   function Upcast is
      new Unchecked_Conversion (Data_Access, Copy_On_Write.Data_Access);
   function Downcast is
      new Unchecked_Conversion (Copy_On_Write.Data_Access, Data_Access);

--  diff (Free)
   procedure Free is new Unchecked_Deallocation (Data, Data_Access);

   procedure Swap_Element (I, J : Integer; Params : System.Address);
   procedure Swap_Element (I, J : Integer; Params : System.Address) is
      Data : Data_Access := Data_Cast.To_Pointer (Params);
      Temp : constant Element_Type := Data.Items (Index_Type'Val (I));
   begin
      Data.Items (Index_Type'Val (I)) := Data.Items (Index_Type'Val (J));
      Data.Items (Index_Type'Val (J)) := Temp;
   end Swap_Element;

--  diff (Equivalent_Element)
--
--
--
--
--
--

--  diff (Replace_Element)
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

   procedure Free_Data (Data : in out Copy_On_Write.Data_Access);
   procedure Free_Data (Data : in out Copy_On_Write.Data_Access) is
      X : Data_Access := Downcast (Data);
   begin
--  diff
--  diff
--  diff
      Free (X);
      Data := null;
   end Free_Data;

   procedure Allocate_Data (
      Target : out Copy_On_Write.Data_Access;
      Capacity : Count_Type);
   procedure Allocate_Data (
      Target : out Copy_On_Write.Data_Access;
      Capacity : Count_Type)
   is
      New_Data : constant Data_Access := new Data'(
         Capacity_Last => Index_Type'First - 1 + Index_Type'Base (Capacity),
         Super => <>,
         Items => <>);
   begin
      Target := Upcast (New_Data);
   end Allocate_Data;

--  diff (Move_Data)
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
--
--

   procedure Copy_Data (
      Target : out Copy_On_Write.Data_Access;
      Source : not null Copy_On_Write.Data_Access;
      Length : Natural;
      Capacity : Natural);
   procedure Copy_Data (
      Target : out Copy_On_Write.Data_Access;
      Source : not null Copy_On_Write.Data_Access;
      Length : Natural;
      Capacity : Natural)
   is
      S : constant not null Data_Access := Downcast (Source);
      T : not null Data_Access := new Data'(
         Capacity_Last => Index_Type'First - 1 + Index_Type'Base (Capacity),
         Super => <>,
         Items => <>);
      subtype R is Extended_Index range
         Index_Type'First ..
         Index_Type'First - 1 + Index_Type'Base (Length);
   begin
      T.Items (R) := S.Items (R);
--  diff
--  diff
--  diff
--  diff
      T.Super.Max_Length := Length;
      Target := Upcast (T);
   end Copy_Data;

   procedure Unique (Container : in out Vector; To_Update : Boolean);
   procedure Unique (Container : in out Vector; To_Update : Boolean) is
   begin
      Copy_On_Write.Unique (
         Container.Super'Access,
         To_Update,
         Container.Length,
         Capacity (Container),
         Allocate => Allocate_Data'Access,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
   end Unique;

   function Array_To_Vector (
      Source : Element_Array;
      Capacity : Count_Type)
      return Vector;
   function Array_To_Vector (
      Source : Element_Array;
      Capacity : Count_Type)
      return Vector
   is
      Length : constant Count_Type := Source'Length;
      New_Capacity : constant Count_Type := Count_Type'Max (Capacity, Length);
   begin
      return Result : Vector := (Finalization.Controlled with
         Super => <>,
         Length => Length)
      do
         if New_Capacity /= 0 then
            declare
               Capacity_Last : constant Extended_Index :=
                  Index_Type'First - 1 + Index_Type'Base (New_Capacity);
               Last : constant Extended_Index :=
                  Index_Type'First - 1 + Index_Type'Base (Length);
               New_Data : Data_Access;
            begin
               New_Data := new Data'(
                  Capacity_Last => Capacity_Last,
                  Super => <>,
                  Items => Source & (Last + 1 .. Capacity_Last => <>));
               New_Data.Super.Max_Length := Length;
               --  follow
               Result.Super.Data := Upcast (New_Data);
               New_Data.Super.Super.Follower := Result.Super'Unchecked_Access;
            end;
         end if;
      end return;
   end Array_To_Vector;

   --  implementation

   procedure Adjust (Object : in out Vector) is
   begin
      Copy_On_Write.Adjust (Object.Super'Access);
   end Adjust;

   procedure Assign (Target : in out Vector; Source : Vector) is
   begin
      Copy_On_Write.Assign (
         Target.Super'Access,
         Source.Super'Access,
         Free => Free_Data'Access);
      Target.Length := Source.Length;
   end Assign;

   procedure Append (Container : in out Vector; New_Item : Vector) is
   begin
      if New_Item.Length > 0 then
         declare
            Old_Length : constant Count_Type := Container.Length;
         begin
            if Old_Length = 0 then
               Assign (Container, New_Item);
            else
               Set_Length (Container, Old_Length + New_Item.Length);
               declare
                  subtype R1 is Index_Type range
                     Index_Type'First + Index_Type'Base (Old_Length) ..
                     Last_Index (Container);
                  subtype R2 is Index_Type range
                     Index_Type'First ..
                     Last_Index (New_Item);
               begin
                  Downcast (Container.Super.Data).Items (R1) :=
                     Downcast (New_Item.Super.Data).Items (R2);
               end;
            end if;
         end;
      end if;
   end Append;

   procedure Append (
      Container : in out Vector;
      New_Item : Element_Type;
      Count : Count_Type := 1)
   is
      Old_Length : constant Count_Type := Container.Length;
   begin
      Set_Length (Container, Old_Length + Count);
      for I in
         Index_Type'First + Index_Type'Base (Old_Length) ..
         Last_Index (Container)
      loop
         Downcast (Container.Super.Data).Items (I) := New_Item;
--  diff
--  diff
      end loop;
   end Append;

   function Capacity (Container : Vector) return Count_Type is
   begin
      if Container.Super.Data = null then
         return 0;
      else
         return Downcast (Container.Super.Data).Items'Length;
      end if;
   end Capacity;

   procedure Clear (Container : in out Vector) is
   begin
      Copy_On_Write.Clear (
         Container.Super'Access,
         Free => Free_Data'Access);
      Container.Length := 0;
   end Clear;

   function Constant_Reference (
      Container : aliased Vector;
      Index : Index_Type)
      return Constant_Reference_Type is
   begin
      Unique (Container'Unrestricted_Access.all, False);
      declare
         Data : constant Data_Access := Downcast (Container.Super.Data);
      begin
         Data.Super.Is_Aliased := True;
         return (Element => Data.Items (Index)'Access);
      end;
   end Constant_Reference;

   function Constant_Reference (
      Container : aliased Vector)
      return Slicing.Constant_Reference_Type is
   begin
      return Constant_Reference (
         Container,
         Index_Type'First,
         Last_Index (Container));
   end Constant_Reference;

   function Constant_Reference (
      Container : aliased Vector;
      First_Index : Index_Type;
      Last_Index : Extended_Index)
      return Slicing.Constant_Reference_Type is
   begin
      Unique (Container'Unrestricted_Access.all, False);
      declare
         Data : constant Data_Access := Downcast (Container.Super.Data);
      begin
         Data.Super.Is_Aliased := True;
         return Slicing.Constant_Slice (
            Data.Items'Unrestricted_Access,
            First_Index,
            Last_Index);
      end;
   end Constant_Reference;

   function Contains (Container : Vector; Item : Element_Type)
      return Boolean is
   begin
      return Find_Index (Container, Item) /= No_Index;
   end Contains;

   function Copy (Source : Vector; Capacity : Count_Type := 0) return Vector is
   begin
      return Result : Vector := Source do
         Reserve_Capacity (Result, Capacity);
      end return;
   end Copy;

   procedure Delete (
      Container : in out Vector;
      Index : Extended_Index;
      Count : Count_Type := 1) is
   begin
      if Index + Index_Type'Base (Count) =
         Index_Type'First + Index_Type'Base (Container.Length)
      then
         Delete_Last (Container, Count);
      else
         Unique (Container, True);
         declare
            Old_Length : constant Count_Type := Container.Length;
            Moving : constant Index_Type'Base :=
               (Index_Type'First + Index_Type'Base (Old_Length))
               - (Index + Index_Type'Base (Count))
               - 1;
            Before : constant Index_Type := Index + Index_Type'Base (Count);
            After : constant Index_Type := Index;
         begin
            Set_Length (Container, Old_Length - Count);
--  diff
--  diff
--  diff
            Downcast (Container.Super.Data).Items (After .. After + Moving) :=
               Downcast (Container.Super.Data).Items
                  (Before .. Before + Moving);
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
         end;
      end if;
   end Delete;

   procedure Delete_First (
      Container : in out Vector;
      Count : Count_Type := 1) is
   begin
      Delete (Container, Index_Type'First, Count => Count);
   end Delete_First;

   procedure Delete_Last (
      Container : in out Vector;
      Count : Count_Type := 1) is
   begin
      Set_Length (Container, Container.Length - Count);
   end Delete_Last;

   function Element (Container : Vector'Class; Index : Index_Type)
      return Element_Type is
   begin
      return Container.Constant_Reference (Index).Element.all;
   end Element;

   function Empty_Vector return Vector is
   begin
      return (Finalization.Controlled with
         Super => <>,
         Length => 0);
   end Empty_Vector;

   function Find (Container : Vector; Item : Element_Type) return Cursor is
   begin
      return Find (Container, Item, Index_Type'First);
   end Find;

   function Find (
      Container : Vector;
      Item : Element_Type;
      Position : Cursor) return Cursor is
   begin
      return Find_Index (Container, Item, Position);
   end Find;

   function Find_Index (
      Container : Vector;
      Item : Element_Type;
      Index : Index_Type := Index_Type'First)
      return Extended_Index is
   begin
      for I in Index .. Last_Index (Container) loop
         if Downcast (Container.Super.Data).Items (I) = Item then
--  diff
--  diff
--  diff
            return I;
         end if;
      end loop;
      return No_Index;
   end Find_Index;

   function First (Container : Vector) return Cursor is
   begin
      if Container.Length = 0 then
         return No_Element;
      else
         return Index_Type'First;
      end if;
   end First;

   function First (Object : Iterator) return Cursor is
   begin
      return Object.First;
   end First;

   function First_Index (Container : Vector) return Index_Type is
      pragma Unreferenced (Container);
   begin
      return Index_Type'First;
   end First_Index;

   function Generic_Array_To_Vector (S : Element_Array) return Vector is
   begin
      return Array_To_Vector (Vectors.Element_Array (S), 0);
   end Generic_Array_To_Vector;

   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position > No_Index;
   end Has_Element;

   procedure Insert (
      Container : in out Vector;
      Before : Extended_Index;
      New_Item : Vector)
   is
      Position : Cursor;
   begin
      Insert (Container, Before, New_Item, Position);
   end Insert;

   procedure Insert (
      Container : in out Vector;
      Before : Cursor;
      New_Item : Vector;
      Position : out Cursor) is
   begin
      if Container.Length = 0 then
         Position := Before;
         Assign (Container, New_Item);
      else
         Insert_Space (Container, Before, Position, New_Item.Length);
         Downcast (Container.Super.Data).Items (
            Before ..
            Before + Index_Type'Base (New_Item.Length) - 1) :=
            Downcast (New_Item.Super.Data).Items;
--  diff
--  diff
      end if;
   end Insert;

   procedure Insert (
      Container : in out Vector;
      Before : Extended_Index;
      New_Item : Element_Type;
      Count : Count_Type := 1)
   is
      Position : Cursor;
   begin
      Insert (Container, Before, New_Item, Position, Count);
   end Insert;

   procedure Insert (
      Container : in out Vector;
      Before : Cursor;
      New_Item : Element_Type;
      Position : out Cursor;
      Count : Count_Type := 1) is
   begin
      Insert_Space (Container, Before, Position, Count);
      for I in Before .. Before + Index_Type'Base (Count) - 1 loop
         Downcast (Container.Super.Data).Items (I) := New_Item;
--  diff
--  diff
      end loop;
   end Insert;

   procedure Insert_Space (
      Container : in out Vector;
      Before : Extended_Index;
      Count : Count_Type := 1)
   is
      Position : Cursor;
   begin
      Insert_Space (Container, Before, Position, Count);
   end Insert_Space;

   procedure Insert_Space (
      Container : in out Vector;
      Before : Cursor;
      Position : out Cursor;
      Count : Count_Type := 1) is
   begin
      Position := Before;
      if Before = Index_Type'First + Index_Type'Base (Container.Length) then
         Set_Length (Container, Container.Length + Count);
      else
         declare
            Old_Length : constant Count_Type := Container.Length;
            Moving : constant Index_Type'Base :=
               Last_Index (Container) - Before;
            After : constant Index_Type := Before + Index_Type'Base (Count);
         begin
            Set_Length (Container, Old_Length + Count);
            Unique (Container, True);
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
            Downcast (Container.Super.Data).Items (After .. After + Moving) :=
               Downcast (Container.Super.Data).Items
                  (Before .. Before + Moving);
--  diff
--  diff
--  diff
         end;
      end if;
   end Insert_Space;

   function Is_Empty (Container : Vector) return Boolean is
   begin
      return Container.Length = 0;
   end Is_Empty;

   procedure Iterate (
      Container : Vector'Class;
      Process : not null access procedure (Position : Cursor)) is
   begin
      for I in Index_Type'First .. Last_Index (Container) loop
         Process (I);
      end loop;
   end Iterate;

   function Iterate (Container : Vector)
      return Vector_Iterator_Interfaces.Reversible_Iterator'Class is
   begin
      return Iterator'(First => First (Container), Last => Last (Container));
   end Iterate;

   function Iterate (Container : Vector; First, Last : Cursor)
      return Vector_Iterator_Interfaces.Reversible_Iterator'Class
   is
      pragma Unreferenced (Container);
   begin
      if First > Last then
         return Iterator'(First => No_Element, Last => No_Element);
      else
         return Iterator'(First => First, Last => Last);
      end if;
   end Iterate;

   function Last (Object : Iterator) return Cursor is
   begin
      return Object.Last;
   end Last;

   function Last_Index (Container : Vector) return Extended_Index is
   begin
      return Index_Type'First - 1 + Index_Type'Base (Container.Length);
   end Last_Index;

   function Length (Container : Vector) return Count_Type is
   begin
      return Container.Length;
   end Length;

   procedure Move (Target : in out Vector; Source : in out Vector) is
   begin
      Copy_On_Write.Move (
         Target.Super'Access,
         Source.Super'Access,
         Free => Free_Data'Access);
      Target.Length := Source.Length;
   end Move;

   function Next (Object : Iterator; Position : Cursor) return Cursor is
   begin
      if Position >= Object.Last then
         return No_Element;
      else
         return Position + 1;
      end if;
   end Next;

   procedure Prepend (Container : in out Vector; New_Item : Vector) is
   begin
      Insert (Container, Index_Type'First, New_Item);
   end Prepend;

   procedure Prepend (
      Container : in out Vector;
      New_Item : Element_Type;
      Count : Count_Type := 1) is
   begin
      Insert (Container, Index_Type'First, New_Item, Count);
   end Prepend;

   function Previous (Object : Iterator; Position : Cursor) return Cursor is
   begin
      if Position <= Object.First then
         return No_Element;
      else
         return Position - 1;
      end if;
   end Previous;

   procedure Query_Element (
      Container : Vector'Class;
      Index : Index_Type;
      Process  : not null access procedure (Element : Element_Type)) is
   begin
      Process (Container.Constant_Reference (Index).Element.all);
   end Query_Element;

   function Reference (
      Container : aliased in out Vector;
      Index : Index_Type)
      return Reference_Type is
   begin
      Unique (Container, True);
      declare
         Data : constant Data_Access := Downcast (Container.Super.Data);
      begin
         Data.Super.Is_Aliased := True;
         return (Element => Data.Items (Index)'Access);
      end;
   end Reference;

   function Reference (
      Container : aliased in out Vector)
      return Slicing.Reference_Type
   is
      Last : constant Extended_Index := Last_Index (Container);
   begin
      return Reference (
         Container,
         Index_Type'First,
         Last);
   end Reference;

   function Reference (
      Container : aliased in out Vector;
      First_Index : Index_Type;
      Last_Index : Extended_Index)
      return Slicing.Reference_Type is
   begin
      Unique (Container, True);
      declare
         Data : constant Data_Access := Downcast (Container.Super.Data);
      begin
         Data.Super.Is_Aliased := True;
         return Slicing.Slice (
            Data.Items'Unrestricted_Access,
            First_Index,
            Last_Index);
      end;
   end Reference;

   procedure Replace_Element (
      Container : in out Vector;
      Index : Index_Type;
      New_Item : Element_Type) is
   begin
      Unique (Container, True);
      Downcast (Container.Super.Data).Items (Index) := New_Item;
--  diff
--  diff
   end Replace_Element;

   procedure Reserve_Capacity (
      Container : in out Vector;
      Capacity : Count_Type)
   is
      New_Capacity : constant Count_Type :=
         Count_Type'Max (Capacity, Container.Length);
   begin
      Copy_On_Write.Reserve_Capacity (
         Container.Super'Access,
         True,
         Container.Length,
         New_Capacity,
         New_Capacity /= Vectors.Capacity (Container),
         Allocate => Allocate_Data'Access,
         Move => Copy_Data'Access,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
   end Reserve_Capacity;

   procedure Reverse_Elements (Container : in out Vector) is
   begin
      Unique (Container, True);
      Inside.Array_Sorting.In_Place_Reverse (
         Index_Type'Pos (Index_Type'First),
         Index_Type'Pos (Last_Index (Container)),
         Data_Cast.To_Address (Downcast (Container.Super.Data)),
         Swap => Swap_Element'Access);
   end Reverse_Elements;

   function Reverse_Find (Container : Vector; Item : Element_Type)
      return Cursor is
   begin
      return Reverse_Find_Index (Container, Item);
   end Reverse_Find;

   function Reverse_Find (
      Container : Vector;
      Item : Element_Type;
      Position : Cursor)
      return Cursor is
   begin
      return Reverse_Find_Index (Container, Item, Position);
   end Reverse_Find;

   function Reverse_Find_Index (
      Container : Vector;
      Item : Element_Type;
      Index : Index_Type := Index_Type'Last)
      return Extended_Index
   is
      Start : constant Extended_Index :=
         Extended_Index'Min (Index, Last_Index (Container));
   begin
      for I in reverse Index_Type'First .. Start loop
         if Downcast (Container.Super.Data).Items (I) = Item then
--  diff
--  diff
--  diff
            return I;
         end if;
      end loop;
      return No_Index;
   end Reverse_Find_Index;

   procedure Reverse_Iterate (
      Container : Vector'Class;
      Process : not null access procedure (Position : Cursor)) is
   begin
      for I in reverse Index_Type'First .. Last_Index (Container) loop
         Process (I);
      end loop;
   end Reverse_Iterate;

   procedure Set_Length (Container : in out Vector; Length : Count_Type) is
   begin
      Copy_On_Write.Set_Length (
         Container.Super'Access,
         Container.Length,
         Capacity (Container),
         Length,
         Allocate => Allocate_Data'Access,
         Move => Copy_Data'Access,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
      Container.Length := Length;
   end Set_Length;

   procedure Swap (Container : in out Vector; I, J : Index_Type) is
   begin
      Unique (Container, True);
      Swap_Element (
         Index_Type'Pos (I),
         Index_Type'Pos (J),
         Data_Cast.To_Address (Downcast (Container.Super.Data)));
   end Swap;

   function To_Cursor (Container : Vector; Index : Extended_Index)
      return Cursor
   is
      pragma Unreferenced (Container);
   begin
      return Cursor (Index);
   end To_Cursor;

   function To_Vector (Length : Count_Type) return Vector is
   begin
      return Result : Vector do
         Insert_Space (Result, Index_Type'First, Length);
      end return;
   end To_Vector;

   function To_Vector (New_Item : Element_Type; Length : Count_Type)
      return Vector is
   begin
      return Result : Vector do
         Append (Result, New_Item, Length);
      end return;
   end To_Vector;

   procedure Update_Element (
      Container : in out Vector'Class;
      Index : Index_Type;
      Process : not null access procedure (Element : in out Element_Type)) is
   begin
      Process (Container.Reference (Index).Element.all);
   end Update_Element;

   function "=" (Left, Right : Vector) return Boolean is
   begin
      if Left.Length /= Right.Length then
         return False;
      elsif Left.Super.Data = Right.Super.Data then
         return True;
      else
         for I in Index_Type'First .. Last_Index (Left) loop
            if Downcast (Left.Super.Data).Items (I) /=
               Downcast (Right.Super.Data).Items (I)
            then
               return False;
            end if;
--  diff
--  diff
--  diff
--  diff
--  diff
         end loop;
         return True;
      end if;
   end "=";

   function "&" (Left, Right : Vector) return Vector is
   begin
      return Result : Vector := Left do
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : Vector; Right : Element_Type) return Vector is
   begin
      return Result : Vector := Left do
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left : Element_Type; Right : Vector) return Vector is
   begin
      return Result : Vector do
         Reserve_Capacity (Result, 1 + Right.Length);
         Append (Result, Left);
         Append (Result, Right);
      end return;
   end "&";

   function "&" (Left, Right : Element_Type) return Vector is
   begin
      return Result : Vector do
         Reserve_Capacity (Result, 2);
         Append (Result, Left);
         Append (Result, Right);
      end return;
   end "&";

   package body Generic_Sorting is

      function LT (Left, Right : Integer; Params : System.Address)
         return Boolean;
      function LT (Left, Right : Integer; Params : System.Address)
         return Boolean
      is
         Data : constant Data_Access := Data_Cast.To_Pointer (Params);
      begin
         return Data.Items (Index_Type'Val (Left)) <
            Data.Items (Index_Type'Val (Right));
      end LT;

      function Is_Sorted (Container : Vector) return Boolean is
      begin
         return Inside.Array_Sorting.Is_Sorted (
            Index_Type'Pos (Index_Type'First),
            Index_Type'Pos (Last_Index (Container)),
            Data_Cast.To_Address (Downcast (Container.Super.Data)),
            LT => LT'Access);
      end Is_Sorted;

      procedure Sort (Container : in out Vector) is
      begin
         Unique (Container, True);
         Inside.Array_Sorting.In_Place_Merge_Sort (
            Index_Type'Pos (Index_Type'First),
            Index_Type'Pos (Last_Index (Container)),
            Data_Cast.To_Address (Downcast (Container.Super.Data)),
            LT => LT'Access,
            Swap => Swap_Element'Access);
      end Sort;

      procedure Merge (Target : in out Vector; Source : in out Vector) is
      begin
         if Source.Length > 0 then
            declare
               Old_Length : constant Count_Type := Target.Length;
            begin
               if Old_Length = 0 then
                  Move (Target, Source);
               else
                  Append (Target, Source);
                  Unique (Target, True);
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
--  diff
                  Set_Length (Source, 0);
                  Inside.Array_Sorting.In_Place_Merge (
                     Index_Type'Pos (Index_Type'First),
                     Integer (Index_Type'First) - 1 + Integer (Old_Length),
                     Index_Type'Pos (Last_Index (Target)),
                     Data_Cast.To_Address (Downcast (Target.Super.Data)),
                     LT => LT'Access,
                     Swap => Swap_Element'Access);
               end if;
            end;
         end if;
      end Merge;

   end Generic_Sorting;

   package body Streaming is

      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Item : out Vector)
      is
         Length : Count_Type'Base;
      begin
         Clear (Item);
         Count_Type'Base'Read (Stream, Length);
         if Length > 0 then
            Set_Length (Item, Length);
            Element_Array'Read (
               Stream,
               Downcast (Item.Super.Data).Items (
                  Index_Type'First ..
                  Last_Index (Item)));
         end if;
      end Read;

      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Item : Vector)
      is
         Length : constant Count_Type := Vectors.Length (Item);
      begin
         Count_Type'Base'Write (Stream, Length);
         if Length > 0 then
            Element_Array'Write (
               Stream,
               Downcast (Item.Super.Data).Items (
                  Index_Type'First ..
                  Last_Index (Item)));
         end if;
      end Write;

   end Streaming;

end Ada.Containers.Vectors;
