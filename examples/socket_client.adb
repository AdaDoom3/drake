with Ada.Streams.Stream_IO.Sockets;
with Ada.Text_IO;
procedure socket_client is
begin
	declare
		End_Point : constant Ada.Streams.Stream_IO.Sockets.End_Point :=
			Ada.Streams.Stream_IO.Sockets.Resolve ("google.com", 80);
		File : Ada.Streams.Stream_IO.File_Type :=
			Ada.Streams.Stream_IO.Sockets.Connect (End_Point);
		-- [gcc-4.7] Connect (Resolve (...)) causes too early finalization
	begin
		pragma Assert (Ada.Streams.Stream_IO.Is_Open (File));
		pragma Assert (Ada.Streams.Stream_IO.Stream (File).all
			not in Ada.Streams.Seekable_Stream_Type);
		String'Write (
			Ada.Streams.Stream_IO.Stream (File),
			"GET / HTTP/1.0" & ASCII.LF & ASCII.LF);
		declare
			C : Character;
		begin
			loop
				Character'Read (
					Ada.Streams.Stream_IO.Stream (File),
					C);
				Ada.Text_IO.Put (C);
			end loop;
		exception
			when Ada.Streams.Stream_IO.End_Error => null;
		end;
	end;
	pragma Debug (Ada.Debug.Put ("OK"));
end socket_client;
