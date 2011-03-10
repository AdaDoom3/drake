with System.Storage_Elements;
package body Ada.Strings.Generic_Fixed is
   use type System.Address;
   use type System.Storage_Elements.Storage_Offset;

   --  gcc's builtin-function
   function memchr (
      s : System.Address;
      c : System.Storage_Elements.Storage_Element;
      n : System.Storage_Elements.Storage_Count)
      return System.Address;
   pragma Import (Intrinsic, memchr, "__builtin_memchr");

   procedure Move (
      Source : String_Type;
      Target : out String_Type;
      Drop : Truncation := Error;
      Justify : Alignment := Left;
      Pad : Character_Type := Space)
   is
      Side : constant array (Alignment) of Trim_End := (
         Left => Right,
         Center => Both,
         Right => Left);
      Source_First : Positive;
      Source_Last : Natural;
      Target_First : Positive;
      Target_Last : Natural;
   begin
      Trim (Source, Side (Justify), Pad, Pad, Source_First, Source_Last);
      if Source_Last - Source_First + 1 > Target'Length then
         case Drop is
            when Left =>
               Source_First := Source_Last - (Target'Length - 1);
            when Right =>
               Source_Last := Source_First + (Target'Length - 1);
            when Error =>
               raise Length_Error;
         end case;
      end if;
      case Justify is
         when Left =>
            Target_First := Target'First;
            Target_Last := Target_First + (Source_Last - Source_First);
         when Center =>
            Target_First := (Target'First + Target'Last -
               (Source_Last - Source_First)) / 2;
            Target_Last := Target_First + (Source_Last - Source_First);
         when Right =>
            Target_Last := Target'Last;
            Target_First := Target_Last - (Source_Last - Source_First);
      end case;
      for I in Target'First .. Target_First - 1 loop
         Target (I) := Pad;
      end loop;
      Target (Target_First .. Target_Last) :=
         Source (Source_First .. Source_Last);
      for I in Target_Last + 1 .. Target'Last loop
         Target (I) := Pad;
      end loop;
   end Move;

   function Index (
      Source : String_Type;
      Pattern : Character_Type;
      From : Positive;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Forward (Source (From .. Source'Last), Pattern);
         when Backward =>
            return Index_Backward (Source (Source'First .. From), Pattern);
      end case;
   end Index;

   function Index (
      Source : String_Type;
      Pattern : Character_Type;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Forward (Source, Pattern);
         when Backward =>
            return Index_Backward (Source, Pattern);
      end case;
   end Index;

   function Index_Forward (Source : String_Type; Pattern : Character_Type)
      return Natural is
   begin
      if Character_Type'Size = Character'Size then
         declare
            Result : constant System.Address := memchr (
               Source'Address,
               Character_Type'Pos (Pattern),
               Source'Length);
         begin
            if Result = System.Null_Address then
               return 0;
            else
               return Source'First + Integer (Result - Source'Address);
            end if;
         end;
      else
         for I in Source'Range loop
            if Source (I) = Pattern then
               return I;
            end if;
         end loop;
         return 0;
      end if;
   end Index_Forward;

   function Index_Backward (Source : String_Type; Pattern : Character_Type)
      return Natural is
   begin
      --  __builtin_memrchr does not exist...
      for I in reverse Source'Range loop
         if Source (I) = Pattern then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Backward;

   function Index (
      Source : String_Type;
      Pattern : String_Type;
      From : Positive;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Forward (Source (From .. Source'Last), Pattern);
         when Backward =>
            return Index_Backward (
               Source (
                  Source'First ..
                  Natural'Min (From + (Pattern'Length - 1), Source'Last)),
               Pattern);
      end case;
   end Index;

   function Index (
      Source : String_Type;
      Pattern : String_Type;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Forward (Source, Pattern);
         when Backward =>
            return Index_Backward (Source, Pattern);
      end case;
   end Index;

   function Index_Forward (Source : String_Type; Pattern : String_Type)
      return Natural is
   begin
      if Pattern'Length = 0 then
         raise Pattern_Error;
      else
         declare
            Current : Natural := Source'First;
            Last : constant Integer := Source'Last - Pattern'Length + 1;
         begin
            while Current <= Last loop
               Current := Index_Forward (
                  Source (Current .. Last),
                  Pattern (Pattern'First));
               exit when Current = 0;
               if Source (Current .. Current + Pattern'Length - 1) =
                  Pattern
               then
                  return Current;
               end if;
               Current := Current + 1;
            end loop;
            return 0;
         end;
      end if;
   end Index_Forward;

   function Index_Backward (Source : String_Type; Pattern : String_Type)
      return Natural is
   begin
      if Pattern'Length = 0 then
         raise Pattern_Error;
      else
         declare
            Current : Integer := Source'Last - Pattern'Length + 1;
         begin
            while Current >= Source'First loop
               Current := Index_Backward (
                  Source (Source'First .. Current),
                  Pattern (Pattern'First));
               exit when Current = 0;
               if Source (Current .. Current + Pattern'Length - 1) =
                  Pattern
               then
                  return Current;
               end if;
               Current := Current - 1;
            end loop;
            return 0;
         end;
      end if;
   end Index_Backward;

   function Index_Non_Blank (
      Source : String_Type;
      From : Positive;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Non_Blank_Forward (Source (From .. Source'Last));
         when Backward =>
            return Index_Non_Blank_Backward (Source (Source'First .. From));
      end case;
   end Index_Non_Blank;

   function Index_Non_Blank (
      Source : String_Type;
      Going : Direction := Forward)
      return Natural is
   begin
      case Going is
         when Forward =>
            return Index_Non_Blank_Forward (Source);
         when Backward =>
            return Index_Non_Blank_Backward (Source);
      end case;
   end Index_Non_Blank;

   function Index_Non_Blank_Forward (Source : String_Type) return Natural is
   begin
      for I in Source'Range loop
         if Source (I) /= Space then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Non_Blank_Forward;

   function Index_Non_Blank_Backward (Source : String_Type) return Natural is
   begin
      for I in reverse Source'Range loop
         if Source (I) /= Space then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Non_Blank_Backward;

   function Count (
      Source : String_Type;
      Pattern : String_Type)
      return Natural
   is
      Position : Natural := Source'First;
      Result : Natural := 0;
   begin
      loop
         Position := Index_Forward (Source (Position .. Source'Last), Pattern);
         exit when Position = 0;
         Position := Position + Pattern'Length;
         Result := Result + 1;
      end loop;
      return Result;
   end Count;

   function Replace_Slice (
      Source : String_Type;
      Low : Positive;
      High : Natural;
      By : String_Type)
      return String_Type is
   begin
      if Low - 1 > Source'Last or else High < Source'First - 1 then
         raise Index_Error;
      end if;
      return Source (Source'First .. Low - 1) &
         By &
         Source (Positive'Max (Low, High + 1) .. Source'Last);
   end Replace_Slice;

   procedure Replace_Slice (
      Source : in out String_Type;
      Low : Positive;
      High : Natural;
      By : String_Type;
      Drop : Truncation := Error;
      Justify : Alignment := Left;
      Pad : Character_Type := Space)
   is
      Result : constant String_Type := Replace_Slice (Source, Low, High, By);
   begin
      Move (Result, Source, Drop, Justify, Pad);
   end Replace_Slice;

   function Insert (
      Source : String_Type;
      Before : Positive;
      New_Item : String_Type)
      return String_Type
   is
      Previous_Length : constant Integer := Before - Source'First;
   begin
      if Previous_Length < 0 or else Before > Source'Last + 1 then
         raise Index_Error;
      end if;
      return Result : String_Type (1 .. Source'Length + New_Item'Length) do
         Result (1 .. Previous_Length) :=
            Source (Source'First .. Before - 1);
         Result (Previous_Length + 1 .. Previous_Length + New_Item'Length) :=
            New_Item;
         Result (Previous_Length + New_Item'Length + 1 .. Result'Last) :=
            Source (Before .. Source'Last);
      end return;
   end Insert;

   procedure Insert (
      Source : in out String_Type;
      Before : Positive;
      New_Item : String_Type;
      Drop : Truncation := Error)
   is
      Result : constant String_Type := Insert (Source, Before, New_Item);
   begin
      Move (Result, Source, Drop, Justify => Left, Pad => Space);
   end Insert;

   function Overwrite (
      Source : String_Type;
      Position : Positive;
      New_Item : String_Type)
      return String_Type
   is
      Previous_Length : constant Integer := Position - Source'First;
   begin
      if Previous_Length < 0 or else Position > Source'Last + 1 then
         raise Index_Error;
      end if;
      return Result : String_Type (
         1 ..
         Natural'Max (Source'Length, Previous_Length + New_Item'Length))
      do
         Result (1 .. Previous_Length) :=
            Source (Source'First .. Position - 1);
         Result (Previous_Length + 1 .. Previous_Length + New_Item'Length) :=
            New_Item;
         Result (Previous_Length + New_Item'Length + 1 .. Result'Length) :=
           Source (Position + New_Item'Length .. Source'Last);
      end return;
   end Overwrite;

   procedure Overwrite (
      Source : in out String_Type;
      Position : Positive;
      New_Item : String_Type;
      Drop : Truncation := Right)
   is
      Result : constant String_Type := Overwrite (Source, Position, New_Item);
   begin
      Move (Result, Source, Drop, Justify => Left, Pad => Space);
   end Overwrite;

   function Delete (
      Source : String_Type;
      From : Positive;
      Through : Natural)
      return String_Type is
   begin
      if From > Through then
         return Source;
      else
         return Result : String_Type (
            1 ..
            Source'Length - (Through - From + 1))
         do
            Result (1 .. From - Source'First) :=
               Source (Source'First .. From - 1);
            Result (From - Source'First + 1 .. Result'Last) :=
               Source (Through + 1 .. Source'Last);
         end return;
      end if;
   end Delete;

   procedure Delete (
      Source : in out String_Type;
      From : Positive;
      Through : Natural;
      Justify : Alignment := Left;
      Pad : Character_Type := Space) is
   begin
      Move (
         Delete (Source, From, Through),
         Source,
         Error, -- no raising because Source'Length be not growing
         Justify,
         Pad);
   end Delete;

   function Trim (
      Source : String_Type;
      Side : Trim_End;
      Left : Character_Type := Space;
      Right : Character_Type := Space)
      return String_Type
   is
      First : Positive;
      Last : Natural;
   begin
      Trim (Source, Side, Left, Right, First, Last);
      declare
         subtype T is String_Type (1 .. Last - First + 1);
      begin
         return T (Source (First .. Last));
      end;
   end Trim;

   procedure Trim (
      Source : in out String_Type;
      Side : Trim_End;
      Left : Character_Type := Space;
      Right : Character_Type := Space;
      Justify : Alignment := Strings.Left;
      Pad : Character_Type := Space) is
   begin
      Move (
         Trim (Source, Side, Left, Right), -- copy because it rewrite Source
         Source,
         Error, -- no raising because Source'Length be not growing
         Justify,
         Pad);
   end Trim;

   procedure Trim (
      Source : String_Type;
      Side : Trim_End;
      Left : Character_Type := Space;
      Right : Character_Type := Space;
      First : out Positive;
      Last : out Natural) is
   begin
      First := Source'First;
      Last := Source'Last;
      case Side is
         when Strings.Left | Both =>
            while First <= Last and then Source (First) = Left loop
               First := First + 1;
            end loop;
         when Strings.Right =>
            null;
      end case;
      case Side is
         when Strings.Right | Both =>
            while Last >= First and then Source (Last) = Right loop
               Last := Last - 1;
            end loop;
         when Strings.Left =>
            null;
      end case;
   end Trim;

   function Head (
      Source : String_Type;
      Count : Natural;
      Pad : Character_Type := Space)
      return String_Type
   is
      Taking : constant Natural := Natural'Min (Source'Length, Count);
   begin
      return Result : String_Type (1 .. Count) do
         Result (1 .. Taking) :=
            Source (Source'First .. Source'First + Taking - 1);
         for I in Taking + 1 .. Count loop
            Result (I) := Pad;
         end loop;
      end return;
   end Head;

   procedure Head (
      Source : in out String_Type;
      Count : Natural;
      Justify : Alignment := Left;
      Pad : Character_Type := Space) is
   begin
      Move (
         Head (Source, Count, Pad),
         Source,
         Error, -- no raising because Source'Length be not growing
         Justify,
         Pad);
   end Head;

   function Tail (
      Source : String_Type;
      Count : Natural;
      Pad : Character_Type := Space)
      return String_Type
   is
      Taking : constant Natural := Natural'Min (Source'Length, Count);
   begin
      return Result : String_Type (1 .. Count) do
         for I in 1 .. Count - Taking loop
            Result (I) := Pad;
         end loop;
         Result (Count - Taking + 1 .. Count) :=
            Source (Source'Last - Taking + 1 .. Source'Last);
      end return;
   end Tail;

   procedure Tail (
      Source : in out String_Type;
      Count : Natural;
      Justify : Alignment := Left;
      Pad : Character_Type := Space) is
   begin
      Move (
         Tail (Source, Count, Pad),
         Source,
         Error, -- no raising because Source'Length be not growing
         Justify,
         Pad);
   end Tail;

   function "*" (Left : Natural; Right : Character_Type)
      return String_Type is
   begin
      return (1 .. Left => Right);
   end "*";

   function "*" (Left : Natural; Right : String_Type)
      return String_Type is
   begin
      return Result : String_Type (1 .. Left * Right'Length) do
         declare
            First : Positive := Result'First;
         begin
            for I in 1 .. Left loop
               Result (First .. First + Right'Length - 1) := Right;
               First := First + Right'Length;
            end loop;
         end;
      end return;
   end "*";

   package body Generic_Maps is

      function Last_Of_Index_Backward (
         Source : String_Type;
         Pattern : String_Type;
         From : Positive)
         return Natural;
      function Last_Of_Index_Backward (
         Source : String_Type;
         Pattern : String_Type;
         From : Positive)
         return Natural
      is
         Pattern_Count : Natural := 0;
         Result : Natural := From - 1;
      begin
         declare
            P : Positive := Pattern'First;
         begin
            while P <= Pattern'Last loop
               Pattern_Count := Pattern_Count + 1;
               declare
                  Next : Positive;
                  Code : System.UTF_Conversions.UCS_4;
                  Error : Boolean;
               begin
                  From_UTF (
                     Pattern (P .. Pattern'Last),
                     Next,
                     Code,
                     Error);
                  P := Next + 1;
               end;
            end loop;
         end;
         while Pattern_Count > 0 and then Result < Source'Last loop
            declare
               Next : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean;
            begin
               From_UTF (
                  Source (Result + 1 .. Source'Last),
                  Next,
                  Code,
                  Error);
               Result := Next;
            end;
            Pattern_Count := Pattern_Count - 1;
         end loop;
         return Result;
      end Last_Of_Index_Backward;

      function Index (
         Source : String_Type;
         Pattern : String_Type;
         From : Positive;
         Going : Direction := Forward;
         Mapping : Character_Mapping)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (
                  Source (From .. Source'Last),
                  Pattern,
                  Mapping);
            when Backward =>
               return Index_Backward (
                  Source (
                     Source'First ..
                     Last_Of_Index_Backward (Source, Pattern, From)),
                  Pattern,
                  Mapping);
         end case;
      end Index;

      function Index (
         Source : String_Type;
         Pattern : String_Type;
         Going : Direction := Forward;
         Mapping : Character_Mapping)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (Source, Pattern, Mapping);
            when Backward =>
               return Index_Backward (Source, Pattern, Mapping);
         end case;
      end Index;

      function Index_Forward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : Character_Mapping)
         return Natural
      is
         function M (From : Wide_Wide_Character) return Wide_Wide_Character;
         function M (From : Wide_Wide_Character) return Wide_Wide_Character is
         begin
            return Value (Mapping, From);
         end M;
      begin
         return Index_Forward (Source, Pattern, M'Access);
      end Index_Forward;

      function Index_Backward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : Character_Mapping)
         return Natural
      is
         function M (From : Wide_Wide_Character) return Wide_Wide_Character;
         function M (From : Wide_Wide_Character) return Wide_Wide_Character is
         begin
            return Value (Mapping, From);
         end M;
      begin
         return Index_Backward (Source, Pattern, M'Access);
      end Index_Backward;

      function Index (
         Source : String_Type;
         Pattern : String_Type;
         From : Positive;
         Going : Direction := Forward;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (
                  Source (From .. Source'Last),
                  Pattern,
                  Mapping);
            when Backward =>
               return Index_Backward (
                  Source (
                     Source'First ..
                     Last_Of_Index_Backward (Source, Pattern, From)),
                  Pattern,
                  Mapping);
         end case;
      end Index;

      function Index (
         Source : String_Type;
         Pattern : String_Type;
         Going : Direction := Forward;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (Source, Pattern, Mapping);
            when Backward =>
               return Index_Backward (Source, Pattern, Mapping);
         end case;
      end Index;

      function Index_Forward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return Natural is
      begin
         if Pattern'Length = 0 then
            raise Pattern_Error;
         else
            declare
               Buffer : String_Type (1 .. UTF_Max_Length);
               Current : Natural := Source'First;
            begin
               while Current <= Source'Last loop
                  declare
                     Next : Positive;
                     J, J_Next, P, Character_Length : Positive;
                     Code : System.UTF_Conversions.UCS_4;
                     Error : Boolean;
                  begin
                     From_UTF (
                        Source (Current .. Source'Last),
                        Next,
                        Code,
                        Error);
                     Code := Wide_Wide_Character'Pos (Mapping (
                        Wide_Wide_Character'Val (Code)));
                     To_UTF (Code, Buffer, Character_Length, Error);
                     P := Pattern'First + Character_Length;
                     if Buffer (1 .. Character_Length) =
                        Pattern (Pattern'First .. P - 1)
                     then
                        J_Next := Next;
                        loop
                           if P > Pattern'Last then
                              return Current;
                           end if;
                           J := J_Next + 1;
                           exit when J > Source'Last;
                           From_UTF (
                              Source (J .. Source'Last),
                              J_Next,
                              Code,
                              Error);
                           Code := Wide_Wide_Character'Pos (Mapping (
                              Wide_Wide_Character'Val (Code)));
                           To_UTF (Code, Buffer, Character_Length, Error);
                           exit when Buffer (1 .. Character_Length) /=
                              Pattern (P .. P + Character_Length - 1);
                           P := P + Character_Length;
                        end loop;
                     end if;
                     Current := Next + 1;
                  end;
               end loop;
               return 0;
            end;
         end if;
      end Index_Forward;

      function Index_Backward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return Natural is
      begin
         if Pattern'Length = 0 then
            raise Pattern_Error;
         else
            declare
               Buffer : String_Type (1 .. UTF_Max_Length);
               Current : Natural := Source'Last;
            begin
               while Current >= Source'First loop
                  declare
                     Previous : Natural;
                     J, J_Previous, P, Character_Length : Natural;
                     Code : System.UTF_Conversions.UCS_4;
                     Error : Boolean;
                  begin
                     From_UTF_Reverse (
                        Source (Source'First .. Current),
                        Previous,
                        Code,
                        Error);
                     Code := Wide_Wide_Character'Pos (Mapping (
                        Wide_Wide_Character'Val (Code)));
                     To_UTF (Code, Buffer, Character_Length, Error);
                     P := Pattern'Last - Character_Length;
                     if Buffer (1 .. Character_Length) =
                        Pattern (P + 1 .. Pattern'Last)
                     then
                        J_Previous := Previous;
                        loop
                           if P < Pattern'First then
                              return J_Previous;
                           end if;
                           J := J_Previous - 1;
                           exit when J < Source'First;
                           From_UTF_Reverse (
                              Source (Source'First .. J),
                              J_Previous,
                              Code,
                              Error);
                           Code := Wide_Wide_Character'Pos (Mapping (
                              Wide_Wide_Character'Val (Code)));
                           To_UTF (Code, Buffer, Character_Length, Error);
                           exit when Buffer (1 .. Character_Length) /=
                              Pattern (P - Character_Length + 1 .. P);
                           P := P - Character_Length;
                        end loop;
                     end if;
                     Current := Previous - 1;
                  end;
               end loop;
               return 0;
            end;
         end if;
      end Index_Backward;

      function Index_Per_Element (
         Source : String_Type;
         Pattern : String_Type;
         From : Positive;
         Going : Direction := Forward;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Per_Element_Forward (
                  Source (From .. Source'Last),
                  Pattern,
                  Mapping);
            when Backward =>
               return Index_Per_Element_Backward (
                  Source (
                     Source'First ..
                     Natural'Min (From + (Pattern'Length - 1), Source'Last)),
                  Pattern,
                  Mapping);
         end case;
      end Index_Per_Element;

      function Index_Per_Element (
         Source : String_Type;
         Pattern : String_Type;
         Going : Direction := Forward;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Per_Element_Forward (Source, Pattern, Mapping);
            when Backward =>
               return Index_Per_Element_Backward (Source, Pattern, Mapping);
         end case;
      end Index_Per_Element;

      function Index_Per_Element_Forward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return Natural is
      begin
         if Pattern'Length = 0 then
            raise Pattern_Error;
         else
            for Current in
               Source'First ..
               Source'Last - Pattern'Length + 1
            loop
               declare
                  J, P : Positive;
                  Code : Character_Type;
               begin
                  Code := Mapping (Source (Current));
                  if Code = Pattern (Pattern'First) then
                     P := Pattern'First;
                     J := Current;
                     loop
                        P := P + 1;
                        if P > Pattern'Last then
                           return Current;
                        end if;
                        J := J + 1;
                        exit when J > Source'Last;
                        Code := Mapping (Source (J));
                        exit when Code /= Pattern (P);
                     end loop;
                  end if;
               end;
            end loop;
            return 0;
         end if;
      end Index_Per_Element_Forward;

      function Index_Per_Element_Backward (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return Natural is
      begin
         if Pattern'Length = 0 then
            raise Pattern_Error;
         else
            for Current in reverse
               Source'First + Pattern'Length - 1 ..
               Source'Last
            loop
               declare
                  J, P : Natural;
                  Code : Character_Type;
               begin
                  Code := Mapping (Source (Current));
                  if Code = Pattern (Pattern'Last) then
                     P := Pattern'Last;
                     J := Current;
                     loop
                        P := P - 1;
                        if P < Pattern'First then
                           return J;
                        end if;
                        J := J - 1;
                        exit when J < Source'First;
                        Code := Mapping (Source (J));
                        exit when Code /= Pattern (P);
                     end loop;
                  end if;
               end;
            end loop;
            return 0;
         end if;
      end Index_Per_Element_Backward;

      function Index (
         Source : String_Type;
         Set : Character_Set;
         From : Positive;
         Test : Membership := Inside;
         Going : Direction := Forward)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (Source (From .. Source'Last), Set, Test);
            when Backward =>
               return Index_Backward (
                  Source (Source'First .. From),
                  Set,
                  Test);
         end case;
      end Index;

      function Index (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership := Inside;
         Going : Direction := Forward)
         return Natural is
      begin
         case Going is
            when Forward =>
               return Index_Forward (Source, Set, Test);
            when Backward =>
               return Index_Backward (Source, Set, Test);
         end case;
      end Index;

      function Index_Forward (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership := Inside)
         return Natural
      is
         I : Positive := Source'First;
      begin
         while I <= Source'Last loop
            declare
               I_Next : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean;
            begin
               From_UTF (
                  Source (I .. Source'Last),
                  I_Next,
                  Code,
                  Error);
               if Is_In (Wide_Wide_Character'Val (Code), Set) =
                  (Test = Inside)
               then
                  return I;
               end if;
               I := I_Next + 1;
            end;
         end loop;
         return 0;
      end Index_Forward;

      function Index_Backward (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership := Inside)
         return Natural
      is
         I : Natural := Source'Last;
      begin
         while I >= Source'First loop
            declare
               I_Previous : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean;
            begin
               From_UTF_Reverse (
                  Source (Source'First .. I),
                  I_Previous,
                  Code,
                  Error);
               if Is_In (Wide_Wide_Character'Val (Code), Set) =
                  (Test = Inside)
               then
                  return I;
               end if;
               I := I_Previous - 1;
            end;
         end loop;
         return 0;
      end Index_Backward;

      function Count (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : Character_Mapping)
         return Natural is
      begin
         return Count (Translate (Source, Mapping), Pattern);
      end Count;

      function Count (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return Natural is
      begin
         return Count (Translate (Source, Mapping), Pattern);
      end Count;

      function Count_Per_Element (
         Source : String_Type;
         Pattern : String_Type;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return Natural is
      begin
         return Count (Translate_Per_Element (Source, Mapping), Pattern);
      end Count_Per_Element;

      function Count (
         Source : String_Type;
         Set : Character_Set)
         return Natural
      is
         I : Positive := Source'First;
         Result : Natural := 0;
      begin
         while I <= Source'Last loop
            declare
               I_Next : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean;
            begin
               From_UTF (
                  Source (I .. Source'Last),
                  I_Next,
                  Code,
                  Error);
               if Is_In (Wide_Wide_Character'Val (Code), Set) then
                  Result := Result + 1;
               end if;
               I := I_Next + 1;
            end;
         end loop;
         return Result;
      end Count;

      procedure Find_Token (
         Source : String_Type;
         Set : Character_Set;
         From : Positive;
         Test : Membership;
         First : out Positive;
         Last : out Natural) is
      begin
         Find_Token (Source (From .. Source'Last), Set, Test, First, Last);
      end Find_Token;

      procedure Find_Token (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership;
         First : out Positive;
         Last : out Natural)
      is
         F : constant Natural := Index_Forward (Source, Set, Test);
      begin
         if F >= Source'First then
            First := F;
            Last := Find_Token_Last (Source (First .. Source'Last), Set, Test);
         else
            First := Source'First;
            Last := Source'First - 1;
         end if;
      end Find_Token;

      function Find_Token_Last (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership)
         return Natural
      is
         Last : Natural := Source'First - 1;
      begin
         while Last < Source'Last loop
            declare
               Next : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean; -- ignore
            begin
               From_UTF (
                  Source (Last + 1 .. Source'Last),
                  Next,
                  Code,
                  Error);
               exit when Is_In (Wide_Wide_Character'Val (Code), Set) /=
                  (Test = Inside);
               Last := Next;
            end;
         end loop;
         return Last;
      end Find_Token_Last;

      function Find_Token_First (
         Source : String_Type;
         Set : Character_Set;
         Test : Membership)
         return Positive
      is
         First : Positive := Source'Last + 1;
      begin
         while First > Source'First loop
            declare
               Previous : Positive;
               Code : System.UTF_Conversions.UCS_4;
               Error : Boolean; -- ignore
            begin
               From_UTF_Reverse (
                  Source (Source'First .. First - 1),
                  Previous,
                  Code,
                  Error);
               exit when Is_In (Wide_Wide_Character'Val (Code), Set) /=
                  (Test = Inside);
               First := Previous;
            end;
         end loop;
         return First;
      end Find_Token_First;

      function Translate (
         Source : String_Type;
         Mapping : Character_Mapping)
         return String_Type
      is
         function M (From : Wide_Wide_Character) return Wide_Wide_Character;
         function M (From : Wide_Wide_Character) return Wide_Wide_Character is
         begin
            return Value (Mapping, From);
         end M;
      begin
         return Translate (Source, M'Access);
      end Translate;

      procedure Translate (
         Source : in out String_Type;
         Mapping : Character_Mapping;
         Drop : Truncation := Error;
         Justify : Alignment := Left;
         Pad : Character_Type := Space)
      is
         Result : constant String_Type := Translate (Source, Mapping);
      begin
         Move (Result, Source, Drop, Justify, Pad);
      end Translate;

      function Translate (
         Source : String_Type;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character)
         return String_Type
      is
         Result : String_Type (
            1 ..
            Source'Length * UTF_Max_Length);
         Last : Natural;
         I : Natural := Source'First;
         J : Natural := Result'First;
      begin
         while I <= Source'Last loop
            declare
               Code : System.UTF_Conversions.UCS_4;
               I_Next : Natural;
               J_Next : Natural;
               Error : Boolean; --  ignore
            begin
               --  get single unicode character
               From_UTF (
                  Source (I .. Source'Last),
                  I_Next,
                  Code,
                  Error);
               --  map it
               Code := Wide_Wide_Character'Pos (
                  Mapping (Wide_Wide_Character'Val (Code)));
               --  put it
               To_UTF (
                  Code,
                  Result (J .. Result'Last),
                  J_Next,
                  Error);
               --  forwarding
               I := I_Next + 1;
               J := J_Next + 1;
            end;
         end loop;
         Last := J - 1;
         return Result (1 .. Last);
      end Translate;

      procedure Translate (
         Source : in out String_Type;
         Mapping : not null access function (From : Wide_Wide_Character)
            return Wide_Wide_Character;
         Drop : Truncation := Error;
         Justify : Alignment := Left;
         Pad : Character_Type := Space)
      is
         Result : constant String_Type := Translate (Source, Mapping);
      begin
         Move (Result, Source, Drop, Justify, Pad);
      end Translate;

      function Translate_Per_Element (
         Source : String_Type;
         Mapping : not null access function (From : Character_Type)
            return Character_Type)
         return String_Type is
      begin
         return Result : String_Type (1 .. Source'Length) do
            for I in Result'Range loop
               Result (I) :=
                  Mapping (Source (Source'First - Result'First + I));
            end loop;
         end return;
      end Translate_Per_Element;

      procedure Translate_Per_Element (
         Source : in out String_Type;
         Mapping : not null access function (From : Character_Type)
            return Character_Type) is
      begin
         for I in Source'Range loop
            Source (I) := Mapping (Source (I));
         end loop;
      end Translate_Per_Element;

      function Trim (
         Source : String_Type;
         Left : Character_Set;
         Right : Character_Set)
         return String_Type
      is
         First : Positive;
         Last : Natural;
      begin
         Trim (Source, Left, Right, First, Last);
         declare
            subtype T is String_Type (1 .. Last - First + 1);
         begin
            return T (Source (First .. Last));
         end;
      end Trim;

      procedure Trim (
         Source : in out String_Type;
         Left : Character_Set;
         Right : Character_Set;
         Justify : Alignment := Strings.Left;
         Pad : Character_Type := Space) is
      begin
         Move (
            Trim (Source, Left, Right), -- copy because it rewrite Source
            Source,
            Error, -- no raising because Source'Length be not growing
            Justify,
            Pad);
      end Trim;

      procedure Trim (
         Source : String_Type;
         Left : Character_Set;
         Right : Character_Set;
         First : out Positive;
         Last : out Natural) is
      begin
         First := Find_Token_Last (
            Source,
            Left,
            Inside) + 1;
         Last := Find_Token_First (
            Source (First .. Source'Last),
            Right,
            Inside) - 1;
      end Trim;

   end Generic_Maps;

end Ada.Strings.Generic_Fixed;