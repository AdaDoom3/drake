pragma Check_Policy (Trace, Off);
with Ada.Unchecked_Conversion;
with System.Formatting;
with System.Shared_Locking;
with System.UTF_Conversions.From_8_To_16;
with System.UTF_Conversions.From_8_To_32;
with System.Zero_Terminated_Strings;
package body Ada.Tags is
   pragma Suppress (All_Checks);
   use type System.Address;
   use type System.Storage_Elements.Storage_Offset;

   Nested_Prefix : constant String := "Internal tag at 16#";

   function External_Tag_Impl (DT : Dispatch_Table_Ptr) return String;
   function External_Tag_Impl (DT : Dispatch_Table_Ptr) return String is
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT.TSD);
   begin
      return System.Zero_Terminated_Strings.Value (
         TSD.External_Tag.all'Address);
   end External_Tag_Impl;

   type E_Node;
   type E_Node_Access is access E_Node;
   type E_Node is record
      Left, Right : E_Node_Access;
      Tag : Tags.Tag;
   end record;
   pragma Suppress_Initialization (E_Node);

   procedure E_Insert (
      Node : in out E_Node_Access;
      T : Tag;
      External : String);
   procedure E_Insert (
      Node : in out E_Node_Access;
      T : Tag;
      External : String) is
   begin
      if Node = null then
         Node := new E_Node'(Left => null, Right => null, Tag => T);
      elsif External_Tag_Impl (DT (Node.Tag)) > External then
         E_Insert (Node.Left, T, External);
      elsif External_Tag_Impl (DT (Node.Tag)) < External then
         E_Insert (Node.Right, T, External);
      else
         null; --  already added
      end if;
   end E_Insert;

   function E_Find (Node : E_Node_Access; External : String)
      return E_Node_Access;
   function E_Find (Node : E_Node_Access; External : String)
      return E_Node_Access is
   begin
      if Node = null then
         return null;
      elsif External_Tag_Impl (DT (Node.Tag)) > External then
         return E_Find (Node.Left, External);
      elsif External_Tag_Impl (DT (Node.Tag)) < External then
         return E_Find (Node.Right, External);
      else
         return Node;
      end if;
   end E_Find;

   External_Map : E_Node_Access;

   function DT_With_Checking (T : Tag) return Dispatch_Table_Ptr;
   function DT_With_Checking (T : Tag) return Dispatch_Table_Ptr is
   begin
      if T = No_Tag then
         raise Tag_Error;
      else
         return DT (T);
      end if;
   end DT_With_Checking;

   --  implementation

   function Base_Address (This : System.Address) return System.Address is
      function Offset_To_Top (This : System.Address)
         return System.Storage_Elements.Storage_Offset;
      function Offset_To_Top (This : System.Address)
         return System.Storage_Elements.Storage_Offset
      is
         function Cast is new Unchecked_Conversion (
            System.Address,
            Tag_Ptr);
         T_DT : constant Dispatch_Table_Ptr := DT (Cast (This).all);
      begin
         if T_DT.Offset_To_Top =
            System.Storage_Elements.Storage_Offset'Last
         then
            declare
               type Storage_Offset_Ptr is
                  access all System.Storage_Elements.Storage_Offset;
               function Cast is new Unchecked_Conversion (
                  System.Address,
                  Storage_Offset_Ptr);
               Tag_Size : constant :=
                  Standard'Address_Size / Standard'Storage_Unit;
               Offset_To_Top : constant System.Address := This + Tag_Size;
            begin
               return Cast (Offset_To_Top).all;
            end;
         else
            return T_DT.Offset_To_Top;
         end if;
      end Offset_To_Top;
   begin
      return This - Offset_To_Top (This);
   end Base_Address;

   function Descendant_Tag (External : String; Ancestor : Tag) return Tag is
      Result : constant Tag := Internal_Tag (External);
   begin
      if not Is_Descendant (
         Result,
         Ancestor,
         Primary_Only => False,
         Same_Level => False)
      then
         raise Tag_Error;
      else
         return Result;
      end if;
   end Descendant_Tag;

   function Displace (This : System.Address; T : Tag) return System.Address is
   begin
      if This = System.Null_Address then
         return System.Null_Address;
      else
         declare
            function Cast is new Unchecked_Conversion (
               System.Address,
               Tag_Ptr);
            function Cast is new Unchecked_Conversion (
               System.Address,
               Type_Specific_Data_Ptr);
            Base_Object : constant System.Address := Base_Address (This);
            Base_Tag : constant Tag := Cast (Base_Object).all;
            Obj_DT : constant Dispatch_Table_Ptr := DT (Base_Tag);
            Iface_Table : constant Interface_Data_Ptr :=
               Cast (Obj_DT.TSD).Interfaces_Table;
         begin
            if Iface_Table /= null then
               for Id in 1 .. Iface_Table.Nb_Ifaces loop
                  declare
                     E : Interface_Data_Element
                        renames Iface_Table.Ifaces_Table (Id);
                  begin
                     if E.Iface_Tag = T then
                        return Result : System.Address do
                           if E.Static_Offset_To_Top then
                              Result := Base_Object + E.Offset_To_Top_Value;
                           else
                              Result := Base_Object +
                                 E.Offset_To_Top_Func.all (Base_Object);
                           end if;
                        end return;
                     end if;
                  end;
               end loop;
            end if;
            if Is_Descendant (
               Base_Tag,
               T,
               Primary_Only => True,
               Same_Level => False)
            then
               return Base_Object;
            else
               if Get_Delegation /= null then
                  declare
                     Aggregated : constant System.Address :=
                        Get_Delegation (Base_Object, T);
                  begin
                     if Aggregated /= System.Null_Address then
                        pragma Check (Trace, Debug.Put ("delegating"));
                        return Aggregated;
                     end if;
                  end;
               end if;
               raise Constraint_Error with "invalid interface conversion";
            end if;
         end;
      end if;
   end Displace;

   function DT (T : Tag) return Dispatch_Table_Ptr is
      function Cast is new Unchecked_Conversion (
         System.Address,
         Dispatch_Table_Ptr);
      subtype Dispatch_Table_Wrapper_0 is Dispatch_Table_Wrapper (0);
   begin
      return Cast (System.Address'(T.all'Address -
         Dispatch_Table_Wrapper_0'Size / Standard'Storage_Unit));
   end DT;

   function Expanded_Name (T : Tag) return String is
      DT : constant Dispatch_Table_Ptr := DT_With_Checking (T);
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT.TSD);
   begin
      return System.Zero_Terminated_Strings.Value (
         TSD.Expanded_Name.all'Address);
   end Expanded_Name;

   function External_Tag (T : Tag) return String is
      DT : constant Dispatch_Table_Ptr := DT_With_Checking (T);
   begin
      return Result : constant String := External_Tag_Impl (DT) do
         if Result'Length > Nested_Prefix'Length
            and then Result (
               Result'First + Result'First - 1 ..
               Nested_Prefix'Length) = Nested_Prefix
         then
            null; -- nested
         else
            System.Shared_Locking.Enter;
            E_Insert (External_Map, T, Result); -- library level
            System.Shared_Locking.Leave;
         end if;
      end return;
   end External_Tag;

   function Get_Prim_Op_Kind (T : Tag; Position : Positive)
      return Prim_Op_Kind
   is
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT (T).TSD);
   begin
      return TSD.SSD.SSD_Table (Position).Kind;
   end Get_Prim_Op_Kind;

   function Interface_Ancestor_Tags (T : Tag) return Tag_Array is
      DT : constant Dispatch_Table_Ptr := DT_With_Checking (T);
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT.TSD);
      Intf_Table : constant Interface_Data_Ptr := TSD.Interfaces_Table;
      Length : Natural;
   begin
      if Intf_Table = null then
         Length := 0;
      else
         Length := Intf_Table.Nb_Ifaces;
      end if;
      return Result : Tag_Array (1 .. Length) do
         for I in Result'Range loop
            Result (I) := Intf_Table.Ifaces_Table (I).Iface_Tag;
         end loop;
      end return;
   end Interface_Ancestor_Tags;

   function Internal_Tag (External : String) return Tag is
   begin
      if External'Length >= Nested_Prefix'Length
         and then External (
            External'First ..
            External'First - 1 + Nested_Prefix'Length) = Nested_Prefix
      then
         declare
            function Cast is new Unchecked_Conversion (System.Address, Tag);
            Use_Longest : constant Boolean :=
               Standard'Address_Size > System.Formatting.Unsigned'Size;
            Result : System.Storage_Elements.Integer_Address;
            Last : Natural;
            Error : Boolean;
         begin
            if Use_Longest then
               System.Formatting.Value (
                  External (
                     External'First + Nested_Prefix'Length ..
                     External'Last),
                  Last,
                  System.Formatting.Longest_Unsigned (Result),
                  Base => 16,
                  Error => Error);
            else
               System.Formatting.Value (
                  External (
                     External'First + Nested_Prefix'Length ..
                     External'Last),
                  Last,
                  System.Formatting.Unsigned (Result),
                  Base => 16,
                  Error => Error);
            end if;
            if Error
               or else Last >= External'Last
               or else External (Last + 1) /= '#'
            then
               raise Tag_Error;
            end if;
            return Cast (System.Storage_Elements.To_Address (Result));
         end;
      else
         declare
            Node : E_Node_Access;
         begin
            System.Shared_Locking.Enter;
            Node := E_Find (External_Map, External);
            System.Shared_Locking.Leave;
            if Node = null then
               raise Tag_Error;
            end if;
            return Node.Tag;
         end;
      end if;
   end Internal_Tag;

   function Is_Abstract (T : Tag) return Boolean is
      DT : constant Dispatch_Table_Ptr := DT_With_Checking (T);
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT.TSD);
   begin
      return TSD.Type_Is_Abstract;
   end Is_Abstract;

   function Is_Descendant (
      Descendant, Ancestor : Tag;
      Primary_Only : Boolean;
      Same_Level : Boolean)
      return Boolean
   is
      D_DT : constant Dispatch_Table_Ptr := DT_With_Checking (Descendant);
      A_DT : constant Dispatch_Table_Ptr := DT_With_Checking (Ancestor);
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      D_TSD : constant Type_Specific_Data_Ptr := Cast (D_DT.TSD);
      A_TSD : constant Type_Specific_Data_Ptr := Cast (A_DT.TSD);
   begin
      if Same_Level and then D_TSD.Access_Level /= A_TSD.Access_Level then
         return False;
      else
         case A_DT.Signature is
            when Primary_DT => --  tagged record
               declare
                  Offset : constant Integer := D_TSD.Idepth - A_TSD.Idepth;
               begin
                  return Offset >= 0
                     and then D_TSD.Tags_Table (Offset) = Ancestor;
               end;
            when Secondary_DT | Unknown => --  interface
               if Primary_Only then
                  return False;
               else
                  declare
                     Intf_Table : constant Interface_Data_Ptr :=
                        D_TSD.Interfaces_Table;
                  begin
                     if Intf_Table /= null then
                        for Id in 1 .. Intf_Table.Nb_Ifaces loop
                           if Intf_Table.Ifaces_Table (Id).Iface_Tag =
                              Ancestor
                           then
                              return True;
                           end if;
                        end loop;
                     end if;
                     return False;
                  end;
               end if;
         end case;
      end if;
   end Is_Descendant;

   function Is_Descendant_At_Same_Level (Descendant, Ancestor : Tag)
      return Boolean is
   begin
      return Is_Descendant (
         Descendant,
         Ancestor,
         Primary_Only => False,
         Same_Level => True);
   end Is_Descendant_At_Same_Level;

   function IW_Membership (This : System.Address; T : Tag) return Boolean is
      function Cast is new Unchecked_Conversion (System.Address, Tag_Ptr);
      Base_Object : constant System.Address := Base_Address (This);
      Base_Tag : constant Tag := Cast (Base_Object).all;
   begin
      if Is_Descendant (
         Base_Tag,
         T,
         Primary_Only => False,
         Same_Level => False)
      then
         return True;
      else
         if Get_Delegation /= null then
            declare
               Aggregated : constant System.Address :=
                  Get_Delegation (Base_Object, T);
            begin
               if Aggregated /= System.Null_Address then
                  pragma Check (Trace, Debug.Put ("delegating"));
                  return True;
               end if;
            end;
         end if;
         return False;
      end if;
   end IW_Membership;

   function Parent_Tag (T : Tag) return Tag is
      DT : constant Dispatch_Table_Ptr := DT_With_Checking (T);
      function Cast is new Unchecked_Conversion (
         System.Address,
         Type_Specific_Data_Ptr);
      TSD : constant Type_Specific_Data_Ptr := Cast (DT.TSD);
   begin
      if TSD.Idepth = 0 then
         return No_Tag;
      else
         return TSD.Tags_Table (1);
      end if;
   end Parent_Tag;

   function Wide_Expanded_Name (T : Tag) return Wide_String is
   begin
      return System.UTF_Conversions.From_8_To_16.Convert (Expanded_Name (T));
   end Wide_Expanded_Name;

   function Wide_Wide_Expanded_Name (T : Tag) return Wide_Wide_String is
   begin
      return System.UTF_Conversions.From_8_To_32.Convert (Expanded_Name (T));
   end Wide_Wide_Expanded_Name;

end Ada.Tags;
