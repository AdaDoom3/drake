with Ada.Directories.Inside;
with Ada.Directories.Inside.Do_Copy_File;
with Ada.Unchecked_Conversion;
with Ada.Unchecked_Deallocation;
with System.Native_Time;
with System.Storage_Elements;
package body Ada.Directories is
   use type Directory_Searching.Handle_Type;
   use type System.Storage_Elements.Storage_Offset;

   procedure Free is new Unchecked_Deallocation (String, String_Access);

   --  implementation

   procedure Base_Name (
      Name : String;
      First : out Positive;
      Last : out Natural) is
   begin
      Simple_Name (Name, First, Last);
      if First > Last or else Name (Last) /= '.' then -- AA-A-16 79.a/2
         for I in reverse First .. Last - 1 loop
            if Name (I) = '.' then
               --  Base_Name (".DOTFILE") = ".DOTFILE"
               if I > First then
                  Last := I - 1;
               end if;
               exit;
            end if;
         end loop;
      end if;
   end Base_Name;

   function Base_Name (Name : String) return String is
      First : Positive;
      Last : Natural;
   begin
      Base_Name (Name, First, Last);
      return Name (First .. Last);
   end Base_Name;

   procedure Check_Assigned (Directory_Entry : Directory_Entry_Type) is
   begin
      if Directory_Entry.Path = null then
         raise Status_Error;
      end if;
   end Check_Assigned;

   function Compose (
      Containing_Directory : String := "";
      Name : String;
      Extension : String := "") return String
   is
      --  if you want to fold '.' or '..', use Hierarchical_File_Names.Compose
      Result : String (
         1 ..
         Containing_Directory'Length + Name'Length + Extension'Length + 2);
      Last : Natural;
   begin
      --  append directory
      Last := Containing_Directory'Length;
      if Last > 0 then
         Result (1 .. Last) := Containing_Directory;
         Include_Trailing_Path_Delimiter (Result, Last);
      end if;
      --  append name
      Result (Last + 1 .. Last + Name'Length) := Name;
      Last := Last + Name'Length;
      --  append extension
      if Extension'Length /= 0 then
         Last := Last + 1;
         Result (Last) := '.';
         Result (Last + 1 .. Last + Extension'Length) := Extension;
         Last := Last + Extension'Length;
      end if;
      return Result (1 .. Last);
   end Compose;

   procedure Containing_Directory (
      Name : String;
      First : out Positive;
      Last : out Natural) is
   begin
      First := Name'First;
      Last := Name'First - 1;
      for I in reverse Name'Range loop
         case Name (I) is
            when '/' =>
               Last := I; -- no removing root '/'
               Exclude_Trailing_Path_Delimiter (Name, Last);
               exit; -- found
            when others =>
               null;
         end case;
      end loop;
   end Containing_Directory;

   function Containing_Directory (Name : String) return String is
      First : Positive;
      Last : Natural;
   begin
      Containing_Directory (Name, First, Last);
      return Name (First .. Last);
   end Containing_Directory;

   procedure Copy_File (
      Source_Name : String;
      Target_Name : String;
      Form : String := "";
      Overwrite : Boolean := True)
      renames Inside.Do_Copy_File;

   procedure Create_Directory (New_Directory : String; Form : String := "") is
      pragma Unreferenced (Form);
   begin
      Inside.Create_Directory (New_Directory);
   end Create_Directory;

   procedure Create_Path (New_Directory : String; Form : String := "") is
      pragma Unreferenced (Form);
      First : Positive;
      Created : Natural;
      Last : Positive;
      Step : Boolean;
   begin
      First := New_Directory'First;
      if First <= New_Directory'Last
         and then New_Directory (First) = '/'
      then
         First := First + 1;
      end if;
      Created := First - 1;
      for J in First .. New_Directory'Last loop
         case New_Directory (J) is
            when '/' =>
               Step := True;
               Last := J - 1;
            when others =>
               Step := J = New_Directory'Last;
               Last := J;
         end case;
         if Step then
            if Created < J then
               declare
                  Step_Dir : constant String :=
                     New_Directory (New_Directory'First .. Last);
               begin
                  case Kind (Step_Dir) is
                     when Ordinary_File | Special_File =>
                        raise Use_Error;
                     when Directory =>
                        null;
                  end case;
               exception
                  when Name_Error =>
                     Create_Directory (Step_Dir);
               end;
            end if;
            Created := J;
         end if;
      end loop;
   end Create_Path;

   function Current_Directory return String is
   begin
      return Inside.Current_Directory;
   end Current_Directory;

   procedure Delete_Directory (Directory : String) is
   begin
      Inside.Delete_Directory (Directory);
   end Delete_Directory;

   procedure Delete_File (Name : String) is
   begin
      Inside.Delete_File (Name);
   end Delete_File;

   procedure Delete_Tree (Directory : String) is
      Search : Search_Type;
   begin
      Start_Search (Search, Directory, "*", (others => True));
      while More_Entries (Search) loop
         declare
            Directory_Entry : Directory_Entry_Type;
         begin
            Get_Next_Entry (Search, Directory_Entry);
            declare
               Name : constant String := Full_Name (Directory_Entry);
            begin
               case Kind (Directory_Entry) is
                  when Ordinary_File | Special_File =>
                     Delete_File (Name);
                  when Directories.Directory =>
                     declare
                        Simple : constant String :=
                           Simple_Name (Directory_Entry);
                     begin
                        if Simple /= "." and then Simple /= ".." then
                           Delete_Tree (Name);
                        end if;
                     end;
               end case;
            end;
         end;
      end loop;
      End_Search (Search);
      Delete_Directory (Directory);
   end Delete_Tree;

   procedure Exclude_Trailing_Path_Delimiter (
      S : String;
      Last : in out Natural) is
   begin
      while Last > S'First -- no removing root '/'
         and then S (Last) = '/'
      loop
         Last := Last - 1;
      end loop;
   end Exclude_Trailing_Path_Delimiter;

   function Exists (Name : String) return Boolean is
      Information : aliased Inside.Directory_Entry_Information_Type;
      Error : Boolean;
   begin
      Inside.Get_Information (Name, Information'Access, Error);
      return not Error;
   end Exists;

   procedure Extension (
      Name : String;
      First : out Positive;
      Last : out Natural) is
   begin
      First := Name'Last + 1;
      Last := Name'Last;
      for I in reverse Name'Range loop
         case Name (I) is
            when '/' =>
               exit; -- not found
            when '.' =>
               --  Extension (".DOTFILE") = ""
               if I > Name'First and then Name (I - 1) /= '/' then
                  First := I + 1;
               end if;
               exit; -- found
            when others =>
               null;
         end case;
      end loop;
   end Extension;

   function Extension (Name : String) return String is
      First : Positive;
      Last : Natural;
   begin
      Extension (Name, First, Last);
      return Name (First .. Last);
   end Extension;

   procedure Finalize (Search : in out Search_Type) is
   begin
      if Search.Search.Handle /= null then
         Directory_Searching.End_Search (Search.Search);
         Free (Search.Path);
      end if;
   end Finalize;

   function Full_Name (Name : String) return String is
   begin
      if Name (Name'First) /= '/' then
         return Compose (Current_Directory, Name);
      else
         return Name;
      end if;
   end Full_Name;

   procedure Get_Attributes (
      Name : String;
      Attributes : out Directory_Searching.Directory_Entry_Information_Type)
   is
      Error : Boolean;
   begin
      Inside.Get_Information (Name, Attributes'Unrestricted_Access, Error);
      if Error then
         raise Name_Error;
      end if;
   end Get_Attributes;

   procedure Include_Trailing_Path_Delimiter (
      S : in out String;
      Last : in out Natural) is
   begin
      if S (Last) /= '/' then
         Last := Last + 1;
         S (Last) := '/';
      end if;
   end Include_Trailing_Path_Delimiter;

   function Kind (Name : String) return File_Kind is
      Attributes : Inside.Directory_Entry_Information_Type;
   begin
      Get_Attributes (Name, Attributes);
      return Inside.Kind (Attributes);
   end Kind;

   function Modification_Time (Name : String) return Calendar.Time is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
      Attributes : Inside.Directory_Entry_Information_Type;
   begin
      Get_Attributes (Name, Attributes);
      return Cast (System.Native_Time.To_Time (
         Inside.Modification_Time (Attributes)));
   end Modification_Time;

   procedure Rename (
      Old_Name : String;
      New_Name : String;
      Overwrite : Boolean := True) is
   begin
      Inside.Rename (Old_Name, New_Name, Overwrite);
   end Rename;

   procedure Set_Directory (Directory : String) is
   begin
      Inside.Set_Directory (Directory);
   end Set_Directory;

   procedure Set_Modification_Time (Name : String; Time : Calendar.Time) is
      function Cast is new Unchecked_Conversion (Calendar.Time, Duration);
   begin
      Inside.Set_Modification_Time (
         Name,
         System.Native_Time.To_Native_Time (Cast (Time)));
   end Set_Modification_Time;

   procedure Simple_Name (
      Name : String;
      First : out Positive;
      Last : out Natural) is
   begin
      First := Name'First;
      Last := Name'Last;
      for I in reverse Name'Range loop
         case Name (I) is
            when '/' =>
               First := I + 1;
               exit; -- found
            when others =>
               null;
         end case;
      end loop;
   end Simple_Name;

   function Simple_Name (Name : String) return String is
      First : Positive;
      Last : Natural;
   begin
      Simple_Name (Name, First, Last);
      return Name (First .. Last);
   end Simple_Name;

   function Size (Name : String) return File_Size is
      Attributes : Inside.Directory_Entry_Information_Type;
   begin
      Get_Attributes (Name, Attributes);
      if Inside.Kind (Attributes) /= Ordinary_File then
         raise Name_Error;
      else
         return Inside.Size (Attributes);
      end if;
   end Size;

   function Size (Directory_Entry : Directory_Entry_Type) return File_Size is
   begin
      if Directory_Entry.Path = null
         or else Inside.Kind (Directory_Entry.State_Data) /=
            Ordinary_File
      then
         raise Status_Error;
      else
         return Inside.Size (Directory_Entry.State_Data);
      end if;
   end Size;

   procedure Symbolic_Link (
      Source_Name : String;
      Target_Name : String;
      Overwrite : Boolean := True) is
   begin
      Inside.Symbolic_Link (Source_Name, Target_Name, Overwrite);
   end Symbolic_Link;

   --  directory searching

   procedure Start_Search (
      Search : in out Search_Type;
      Directory : String;
      Pattern : String := "*";
      Filter : Filter_Type := (others => True))
   is
      function Cast is new
         Unchecked_Conversion (Filter_Type, Directory_Searching.Filter_Type);
   begin
      Finalize (Search); -- cleanup
      Directory_Searching.Start_Search (
         Search.Search,
         Directory,
         Pattern,
         Cast (Filter));
      Search.Path := new String'(Full_Name (Directory));
      Search.Count := 0;
      Directory_Searching.Get_Next_Entry (
         Search.Search,
         Search.Data'Access,
         Search.Has_Next);
   end Start_Search;

   function Start_Search (
      Directory : String;
      Pattern : String := "*";
      Filter : Filter_Type := (others => True))
      return Search_Type is
   begin
      return Result : Search_Type do
         Start_Search (Result, Directory, Pattern, Filter);
      end return;
   end Start_Search;

   function More_Entries (Search : Search_Type) return Boolean is
   begin
      return Search.Search.Handle /= null and then Search.Has_Next;
   end More_Entries;

   procedure Get_Next_Entry (
      Search : in out Search_Type;
      Directory_Entry : out Directory_Entry_Type) is
   begin
      if Search.Search.Handle = null or else not Search.Has_Next then
         raise Status_Error;
      else
         --  copy entry and get info
         Directory_Entry.Path := Search.Path; -- overwrite
         Directory_Entry.Entry_Data := Search.Data;
         Directory_Searching.Get_Information (
            Directory_Entry.Path.all,
            Directory_Entry.Entry_Data,
            Directory_Entry.State_Data'Access);
         --  counting
         Search.Count := Search.Count + 1;
         --  search next
         Directory_Searching.Get_Next_Entry (
            Search.Search,
            Search.Data'Access,
            Search.Has_Next);
      end if;
   end Get_Next_Entry;

   procedure Search (
      Directory : String;
      Pattern : String := "*";
      Filter : Filter_Type := (others => True);
      Process : not null access procedure (
         Directory_Entry : Directory_Entry_Type))
   is
      Srch : Search_Type;
      Directory_Entry : Directory_Entry_Type;
   begin
      Start_Search (Srch, Directory, Pattern, Filter);
      while More_Entries (Srch) loop
         Get_Next_Entry (Srch, Directory_Entry);
         Process (Directory_Entry);
      end loop;
      End_Search (Srch);
   end Search;

   --  iterator

   function Has_Element (Position : Cursor) return Boolean is
   begin
      return Position.Search /= null;
   end Has_Element;

   function Constant_Reference (
      Container : aliased Search_Type;
      Position : Cursor)
      return Constant_Reference_Type
   is
      pragma Unreferenced (Container);
   begin
      return (Element => Position.Directory_Entry'Access);
   end Constant_Reference;

   function Iterate (Container : Search_Type)
      return Search_Iterator_Interfaces.Forward_Iterator'Class is
   begin
      return Search_Iterator'(Search => Container'Unrestricted_Access);
   end Iterate;

   overriding function First (Object : Search_Iterator) return Cursor is
   begin
      if Object.Search.Count /= 0 then
         raise Constraint_Error; -- Status_Error?
      end if;
      return Result : Cursor do
         if More_Entries (Object.Search.all) then
            Result.Search := Object.Search;
            Get_Next_Entry (Object.Search.all, Result.Directory_Entry);
            Result.Index := Object.Search.Count;
         end if;
      end return;
   end First;

   overriding function Next (Object : Search_Iterator; Position : Cursor)
      return Cursor is
   begin
      if Object.Search.Count /= Position.Index then
         raise Constraint_Error; -- Status_Error?
      end if;
      return Result : Cursor do
         if More_Entries (Object.Search.all) then
            Result.Search := Object.Search;
            Get_Next_Entry (Object.Search.all, Result.Directory_Entry);
            Result.Index := Object.Search.Count;
         end if;
      end return;
   end Next;

   --  operations on directory entries

   function Simple_Name (Directory_Entry : Directory_Entry_Type)
      return String is
   begin
      Check_Assigned (Directory_Entry);
      return Directory_Searching.Simple_Name (Directory_Entry.Entry_Data);
   end Simple_Name;

   function Full_Name (Directory_Entry : Directory_Entry_Type) return String is
   begin
      Check_Assigned (Directory_Entry);
      return Compose (
         Directory_Entry.Path.all,
         Simple_Name (Directory_Entry));
   end Full_Name;

   function Kind (Directory_Entry : Directory_Entry_Type) return File_Kind is
   begin
      Check_Assigned (Directory_Entry);
      return Inside.Kind (Directory_Entry.State_Data);
   end Kind;

   function Modification_Time (Directory_Entry : Directory_Entry_Type)
      return Calendar.Time
   is
      function Cast is new Unchecked_Conversion (Duration, Calendar.Time);
   begin
      Check_Assigned (Directory_Entry);
      return Cast (
         System.Native_Time.To_Time (
            Inside.Modification_Time (Directory_Entry.State_Data)));
   end Modification_Time;

end Ada.Directories;
