-- *** this line is for test ***
with Ada.Calendar;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Directories.Information;
with Ada.Directories.Temporary;
with Ada.Permissions;
with Ada.Text_IO;
procedure directories is
	use type Ada.Calendar.Time;
begin
	Ada.Debug.Put ("current user: " & Ada.Permissions.User_Name);
	-- iteration
	declare
		procedure Process (Directory_Entry : Ada.Directories.Directory_Entry_Type) is
		begin
			Ada.Debug.Put (Ada.Directories.Simple_Name (Directory_Entry));
			Ada.Debug.Put (Ada.Directories.Information.Owner (Directory_Entry));
			Ada.Debug.Put (Ada.Directories.Information.Group (Directory_Entry));
		end Process;
	begin
		Ada.Directories.Search (".", "*", Process => Process'Access);
	end;
	-- copy
	begin
		Ada.Directories.Copy_File ("%%%%NOTHING1%%%%", "%%%%NOTHING2%%%%");
		raise Program_Error;
	exception
		when Ada.Directories.Name_Error => null;
	end;
	-- modification time
	declare
		Name : String := Ada.Command_Line.Command_Name & "-test";
		File : Ada.Text_IO.File_Type;
		The_Time : constant Ada.Calendar.Time := Ada.Calendar.Time_Of (1999, 7, 1);
	begin
		Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Name);
		Ada.Text_IO.Close (File);
		if abs (Ada.Directories.Modification_Time (Name) - Ada.Calendar.Clock) > 1.0 then
			raise Program_Error;
		end if;
		Ada.Directories.Set_Modification_Time (Name, The_Time);
		if abs (Ada.Directories.Modification_Time (Name) - The_Time) > 1.0 then
			raise Program_Error;
		end if;
		Ada.Directories.Delete_File (Name);
	end;
	-- symbolic link
	declare
		Source_Name : String := Ada.Directories.Full_Name ("directories.adb");
		Linked_Name : String := Ada.Command_Line.Command_Name & "-link";
		File : Ada.Text_IO.File_Type;
	begin
		Ada.Directories.Symbolic_Link (Source_Name, Linked_Name);
		Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Linked_Name);
		if Ada.Text_IO.Get_Line (File) /= "-- *** this line is for test ***" then
			raise Program_Error;
		end if;
		Ada.Text_IO.Close (File);
		if Ada.Directories.Information.Read_Symbolic_Link (Linked_Name) /= Source_Name then
			raise Program_Error;
		end if;
		Ada.Directories.Delete_File (Linked_Name);
	end;
	Ada.Debug.Put ("OK");
end directories;
