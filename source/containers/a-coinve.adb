with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with Ada.Containers.Inside.Array_Sorting;
with System.Address_To_Named_Access_Conversions;
package body Ada.Containers.Indefinite_Vectors is

   package Data_Cast is
      new System.Address_To_Named_Access_Conversions (Data, Data_Access);

   subtype Not_Null_Data_Access is not null Data_Access;
   type Data_Access_Access is access all Not_Null_Data_Access;
   type System_Address_Access is access all System.Address;
   function Upcast is new Unchecked_Conversion (
      Data_Access_Access,
      System_Address_Access);

   procedure Free is new Unchecked_Deallocation (Element_Type, Element_Access);
   procedure Free is new Unchecked_Deallocation (Data, Data_Access);

   procedure Swap_Element (I, J : Integer; Params : System.Address);
   procedure Swap_Element (I, J : Integer; Params : System.Address) is
      Data : Data_Access := Data_Cast.To_Pointer (Params);
      Temp : constant Element_Access := Data.Items (Index_Type'Val (I));
   begin
      Data.Items (Index_Type'Val (I)) := Data.Items (Index_Type'Val (J));
      Data.Items (Index_Type'Val (J)) := Temp;
   end Swap_Element;

   function Equivalent_Element (Left : Element_Access; Right : Element_Type)
      return Boolean;
   function Equivalent_Element (Left : Element_Access; Right : Element_Type)
      return Boolean is
   begin
      return Left /= null and then Left.all = Right;
   end Equivalent_Element;

   procedure Replace_Element (
      Item : in out Element_Access;
      New_Item : access constant Element_Type);
   procedure Replace_Element (
      Item : in out Element_Access;
      New_Item : access constant Element_Type) is
   begin
      Free (Item);
      if New_Item /= null then
         Item := new Element_Type'(New_Item.all);
      end if;
   end Replace_Element;

   procedure Free_Data (Data : System.Address);
   procedure Free_Data (Data : System.Address) is
      X : Data_Access := Data_Cast.To_Pointer (Data);
   begin
      for I in X.Items'Range loop
         Free (X.Items (I));
      end loop;
      Free (X);
   end Free_Data;
--  diff

   procedure Copy_Data (
      Target : out System.Address;
      Source : System.Address;
      Length : Natural;
      Max_Length : Natural;
      Capacity : Natural);
   procedure Copy_Data (
      Target : out System.Address;
      Source : System.Address;
      Length : Natural;
      Max_Length : Natural;
      Capacity : Natural)
   is
      S : constant not null Data_Access := Data_Cast.To_Pointer (Source);
      T : not null Data_Access := new Data'(
         Capacity_Last => Index_Type'First - 1 + Index_Type'Base (Capacity),
         Reference_Count => 1,
         Max_Length => Max_Length,
         Items => <>);
      subtype R is Extended_Index range
         Index_Type'First ..
         Index_Type'First - 1 + Index_Type'Base (Length);
   begin
      if System.Reference_Counting.Shared (S.Reference_Count) then
         for I in R loop
            if S.Items (I) /= null then
               T.Items (I) := new Element_Type'(S.Items (I).all);
            end if;
         end loop;
      else
         for I in R loop
            T.Items (I) := S.Items (I);
            S.Items (I) := null;
         end loop;
      end if;
      Target := T.all'Address;
   end Copy_Data;

   procedure Unique (Container : in out Vector);
   procedure Unique (Container : in out Vector) is
   begin
      Reserve_Capacity (Container, Capacity (Container));
   end Unique;

--  diff (Array_To_Vector)
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
--
--
--
--
--

   --  implementation

   procedure Adjust (Object : in out Vector) is
   begin
      System.Reference_Counting.Adjust (Object.Data.Reference_Count'Access);
   end Adjust;

   procedure Assign (Target : in out Vector; Source : Vector) is
   begin
      System.Reference_Counting.Assign (
         Upcast (Target.Data'Unchecked_Access),
         Target.Data.Reference_Count'Access,
         Upcast (Source.Data'Unrestricted_Access),
         Source.Data.Reference_Count'Access,
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
--  diff
--  diff
               for I in
                  Index_Type'First + Index_Type'Base (Old_Length) ..
                  Last_Index (Container)
               loop
                  Replace_Element (
                     Container.Data.Items (I),
                     New_Item.Data.Items (I - Index_Type'Base (Old_Length)));
               end loop;
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
         Replace_Element (
            Container.Data.Items (I),
            New_Item'Unrestricted_Access);
      end loop;
   end Append;

   function Capacity (Container : Vector) return Count_Type is
   begin
      return Container.Data.Items'Length;
   end Capacity;

   procedure Clear (Container : in out Vector) is
   begin
      System.Reference_Counting.Clear (
         Upcast (Container.Data'Unchecked_Access),
         Container.Data.Reference_Count'Access,
         Free => Free_Data'Access);
      Container.Data := Empty_Data'Unrestricted_Access;
      Container.Length := 0;
   end Clear;

   function Constant_Reference (
      Container : aliased Vector;
      Index : Index_Type)
      return Constant_Reference_Type is
   begin
      return (Element => Container.Data.Items (Index).all'Access);
   end Constant_Reference;

--  diff (Constant_Reference)
--
--
--
--
--
--
--
--

--  diff (Constant_Reference)
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
         Unique (Container);
         declare
            Old_Length : constant Count_Type := Container.Length;
            Moving : constant Index_Type'Base :=
               (Index_Type'First + Index_Type'Base (Old_Length)) -
               (Index + Index_Type'Base (Count)) - 1;
            Before : constant Index_Type := Index + Index_Type'Base (Count);
            After : constant Index_Type := Index;
         begin
            Container.Length := Container.Length - Count;
            for I in After .. After + Index_Type'Base (Count) - 1 loop
               Free (Container.Data.Items (I));
            end loop;
            Container.Data.Items (After .. After + Moving) :=
               Container.Data.Items (Before .. Before + Moving);
            for I in
               Index_Type'First + Index_Type'Base (Container.Length) ..
               Index_Type'First - 1 + Index_Type'Base (Old_Length)
            loop
               Container.Data.Items (I) := null;
            end loop;
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
      Container.Length := Container.Length - Count;
   end Delete_Last;

   function Element (Container : Vector'Class; Index : Index_Type)
      return Element_Type is
   begin
      return Container.Constant_Reference (Index).Element.all;
   end Element;

   function Empty_Vector return Vector is
   begin
      return (Finalization.Controlled with
         Data => Empty_Data'Unrestricted_Access,
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
         if Equivalent_Element (Container.Data.Items (I), Item) then
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

--  diff (Generic_Array_To_Vector)
--
--
--

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
         for I in Before .. Before + Index_Type'Base (New_Item.Length) - 1 loop
            Replace_Element (
               Container.Data.Items (I),
               New_Item.Data.Items (I - Before + Index_Type'First));
         end loop;
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
         Replace_Element (
            Container.Data.Items (I),
            New_Item'Unrestricted_Access);
      end loop;
   end Insert;

--  diff (Insert)
--
--
--
--
--
--
--
--

--  diff (Insert)
--
--
--
--
--
--
--

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
            for I in
               Index_Type'First + Index_Type'Base (Old_Length) ..
               Last_Index (Container)
            loop
               Free (Container.Data.Items (I));
            end loop;
            Container.Data.Items (After .. After + Moving) :=
               Container.Data.Items (Before .. Before + Moving);
            for I in Before .. After - 1 loop
               Container.Data.Items (I) := null;
            end loop;
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
      System.Reference_Counting.Move (
         Upcast (Target.Data'Unchecked_Access),
         Target.Data.Reference_Count'Access,
         Upcast (Source.Data'Unrestricted_Access),
         Sentinel => Empty_Data'Address,
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
      New_Item  : Element_Type;
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
      Unique (Container);
      return (Element => Container.Data.Items (Index).all'Access);
   end Reference;

--  diff (Reference)
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

--  diff (Reference)
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

   procedure Replace_Element (
      Container : in out Vector;
      Index : Index_Type;
      New_Item : Element_Type) is
   begin
      Unique (Container);
      Replace_Element (
         Container.Data.Items (Index),
         New_Item'Unrestricted_Access);
   end Replace_Element;

   procedure Reserve_Capacity (
      Container : in out Vector;
      Capacity : Count_Type) is
   begin
      System.Reference_Counting.Unique (
         Target => Upcast (Container.Data'Unchecked_Access),
         Target_Reference_Count => Container.Data.Reference_Count'Access,
         Target_Length => Container.Length,
         Target_Capacity => Indefinite_Vectors.Capacity (Container),
         Max_Length => Container.Length,
         Capacity => Capacity,
         Sentinel => Empty_Data'Address,
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
--  diff
--  diff
--  diff
   end Reserve_Capacity;

   procedure Reverse_Elements (Container : in out Vector) is
   begin
      Unique (Container);
      Inside.Array_Sorting.In_Place_Reverse (
         Index_Type'Pos (Index_Type'First),
         Index_Type'Pos (Last_Index (Container)),
         Data_Cast.To_Address (Container.Data),
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
         if Equivalent_Element (Container.Data.Items (I), Item) then
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
      System.Reference_Counting.Set_Length (
         Target => Upcast (Container.Data'Unchecked_Access),
         Target_Reference_Count => Container.Data.Reference_Count'Access,
         Target_Length => Container.Length,
         Target_Max_Length => Container.Data.Max_Length'Access,
         Target_Capacity => Capacity (Container),
         New_Length => Length,
         Sentinel => Empty_Data'Address,
         Copy => Copy_Data'Access,
         Free => Free_Data'Access);
      Container.Length := Length;
   end Set_Length;

   procedure Swap (Container : in out Vector; I, J : Index_Type) is
   begin
      Unique (Container);
      Swap_Element (
         Index_Type'Pos (I),
         Index_Type'Pos (J),
         Data_Cast.To_Address (Container.Data));
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
      elsif Left.Data = Right.Data then
         return True;
      else
         for I in Index_Type'First .. Last_Index (Left) loop
            if Left.Data.Items (I) = null then
               if Right.Data.Items (I) /= null then
                  return False;
               end if;
            elsif not Equivalent_Element (
               Right.Data.Items (I),
               Left.Data.Items (I).all)
            then
               return False;
            end if;
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
         return Data.Items (Index_Type'Val (Left)).all <
            Data.Items (Index_Type'Val (Right)).all;
      end LT;

      function Is_Sorted (Container : Vector) return Boolean is
      begin
         return Inside.Array_Sorting.Is_Sorted (
            Index_Type'Pos (Index_Type'First),
            Index_Type'Pos (Last_Index (Container)),
            Data_Cast.To_Address (Container.Data),
            LT => LT'Access);
      end Is_Sorted;

      procedure Sort (Container : in out Vector) is
      begin
         Unique (Container);
         Inside.Array_Sorting.In_Place_Merge_Sort (
            Index_Type'Pos (Index_Type'First),
            Index_Type'Pos (Last_Index (Container)),
            Data_Cast.To_Address (Container.Data),
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
                  Unique (Target);
                  Set_Length (Target, Old_Length + Source.Length);
                  Unique (Source); -- splicing
                  for I in Index_Type'First .. Last_Index (Source) loop
                     Target.Data.Items (I + Index_Type'Base (Old_Length)) :=
                        Source.Data.Items (I);
                     Source.Data.Items (I) := null;
                  end loop;
                  Source.Length := 0;
                  Inside.Array_Sorting.In_Place_Merge (
                     Index_Type'Pos (Index_Type'First),
                     Integer (Index_Type'First) - 1 + Integer (Old_Length),
                     Index_Type'Pos (Last_Index (Target)),
                     Data_Cast.To_Address (Target.Data),
                     LT => LT'Access,
                     Swap => Swap_Element'Access);
               end if;
            end;
         end if;
      end Merge;

   end Generic_Sorting;

   package body No_Primitives is

      procedure Read (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : out Vector)
      is
         Length : Count_Type'Base;
      begin
         Clear (Container);
         Count_Type'Base'Read (Stream, Length);
         if Length > 0 then
            Set_Length (Container, Length);
            for I in Container.Data.Items'Range loop
               pragma Assert (Container.Data.Items (I) = null);
               Container.Data.Items (I) := new Element_Type'(
                  Element_Type'Input (Stream));
            end loop;
         end if;
      end Read;

      procedure Write (
         Stream : not null access Streams.Root_Stream_Type'Class;
         Container : Vector)
      is
         Length : constant Count_Type := Indefinite_Vectors.Length (Container);
      begin
         Count_Type'Base'Write (Stream, Length);
         if Length > 0 then
            for I in Container.Data.Items'Range loop
               Element_Type'Output (
                  Stream,
                  Container.Data.Items (I).all);
            end loop;
         end if;
      end Write;

   end No_Primitives;

end Ada.Containers.Indefinite_Vectors;
