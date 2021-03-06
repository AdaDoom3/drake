with Ada.Exception_Identification.From_Here;
with Ada.Streams.Stream_IO.Inside;
with Ada.Unchecked_Conversion;
with System.Formatting;
with System.Once;
with System.Termination;
with System.Zero_Terminated_WStrings;
with C.psdk_inc.qsocket_types;
with C.psdk_inc.qwsadata;
with C.winnt;
with C.winsock2;
package body Ada.Streams.Stream_IO.Sockets is
   use Exception_Identification.From_Here;
   use type C.signed_int;
   use type C.size_t;
   use type C.psdk_inc.qsocket_types.SOCKET;
   use type C.ws2tcpip.struct_addrinfoW_ptr;

   Flag : aliased System.Once.Flag := 0;
   Failed_To_Initialize : Boolean;
   Data : aliased C.psdk_inc.qwsadata.WSADATA := (others => <>);

   procedure Finalize;
   procedure Finalize is
   begin
      if C.winsock2.WSACleanup /= 0 then
         null; -- ignore error
      end if;
   end Finalize;

   procedure Initialize;
   procedure Initialize is
   begin
      System.Termination.Register_Exit (Finalize'Access);
      if C.winsock2.WSAStartup (16#0202#, Data'Access) /= 0 then
         Failed_To_Initialize := True;
      end if;
   end Initialize;

   procedure Check_Initialize;
   procedure Check_Initialize is
   begin
      System.Once.Initialize (Flag'Access, Initialize'Access);
      if Failed_To_Initialize then
         raise Program_Error; -- ??
      end if;
   end Check_Initialize;

   function Get (
      Host_Name : not null access constant C.winnt.WCHAR;
      Service : not null access constant C.winnt.WCHAR;
      Hints : not null access constant C.ws2tcpip.struct_addrinfoW)
      return End_Point;
   function Get (
      Host_Name : not null access constant C.winnt.WCHAR;
      Service : not null access constant C.winnt.WCHAR;
      Hints : not null access constant C.ws2tcpip.struct_addrinfoW)
      return End_Point
   is
      Data : aliased C.ws2tcpip.struct_addrinfoW_ptr;
      Result : C.signed_int;
   begin
      Result := C.ws2tcpip.GetAddrInfoW (
         Host_Name,
         Service,
         Hints,
         Data'Access);
      if Result /= 0 then
         Raise_Exception (Use_Error'Identity);
      else
         return Result : End_Point do
            Reference (Result).all := Data;
         end return;
      end if;
   end Get;

   --  implementation

   function Resolve (Host_Name : String; Service : String)
      return End_Point is
   begin
      Check_Initialize;
      declare
         Hints : aliased constant C.ws2tcpip.struct_addrinfoW := (
            ai_flags => 0,
            ai_family => C.winsock2.AF_UNSPEC,
            ai_socktype => C.winsock2.SOCK_STREAM,
            ai_protocol => C.winsock2.IPPROTO_TCP,
            ai_addrlen => 0,
            ai_canonname => null,
            ai_addr => null,
            ai_next => null);
         W_Host_Name : C.winnt.WCHAR_array (
            0 ..
            Host_Name'Length * System.Zero_Terminated_WStrings.Expanding);
         W_Service : C.winnt.WCHAR_array (
            0 ..
            Service'Length * System.Zero_Terminated_WStrings.Expanding);
      begin
         System.Zero_Terminated_WStrings.To_C (
            Host_Name,
            W_Host_Name (0)'Access);
         System.Zero_Terminated_WStrings.To_C (
            Service,
            W_Service (0)'Access);
         return Get (
            W_Host_Name (0)'Access,
            W_Service (0)'Access,
            Hints'Access);
      end;
   end Resolve;

   function Resolve (Host_Name : String; Port : Port_Number)
      return End_Point is
   begin
      Check_Initialize;
      declare
         Hints : aliased constant C.ws2tcpip.struct_addrinfoW := (
            ai_flags => 0, -- mingw-w64 header does not have AI_NUMERICSERV
            ai_family => C.winsock2.AF_UNSPEC,
            ai_socktype => C.winsock2.SOCK_STREAM,
            ai_protocol => C.winsock2.IPPROTO_TCP,
            ai_addrlen => 0,
            ai_canonname => null,
            ai_addr => null,
            ai_next => null);
         W_Host_Name : C.winnt.WCHAR_array (
            0 ..
            Host_Name'Length * System.Zero_Terminated_WStrings.Expanding);
         Service : String (1 .. 5);
         Service_Last : Natural;
         W_Service : C.winnt.WCHAR_array (
            0 ..
            Service'Length * System.Zero_Terminated_WStrings.Expanding);
         Error : Boolean;
      begin
         System.Zero_Terminated_WStrings.To_C (
            Host_Name,
            W_Host_Name (0)'Access);
         System.Formatting.Image (
            System.Formatting.Unsigned (Port),
            Service,
            Service_Last,
            Base => 10,
            Error => Error);
         System.Zero_Terminated_WStrings.To_C (
            Service (1 .. Service_Last),
            W_Service (0)'Access);
         return Get (
            W_Host_Name (0)'Access,
            W_Service (0)'Access,
            Hints'Access);
      end;
   end Resolve;

   procedure Connect (File : in out File_Type; Peer : End_Point) is
      function Cast is
         new Unchecked_Conversion (
            C.psdk_inc.qsocket_types.SOCKET,
            C.winnt.HANDLE);
      Socket : C.psdk_inc.qsocket_types.SOCKET :=
         C.psdk_inc.qsocket_types.INVALID_SOCKET;
      I : C.ws2tcpip.struct_addrinfoW_ptr := Reference (Peer).all;
   begin
      while I /= null loop
         Socket := C.winsock2.WSASocket (
            I.ai_family,
            I.ai_socktype,
            I.ai_protocol,
            null,
            0,
            0);
         if Socket /= C.psdk_inc.qsocket_types.INVALID_SOCKET then
            exit when C.winsock2.WSAConnect (
               Socket,
               I.ai_addr,
               C.signed_int (I.ai_addrlen),
               null,
               null,
               null,
               null) = 0;
            if C.winsock2.closesocket (Socket) /= 0 then
               null; -- ignore error
            end if;
            Socket := C.psdk_inc.qsocket_types.INVALID_SOCKET;
         end if;
         I := I.ai_next;
      end loop;
      if Socket = C.psdk_inc.qsocket_types.INVALID_SOCKET then
         Raise_Exception (Use_Error'Identity);
      else
         Inside.Open (
            File,
            Cast (Socket),
            Append_File, -- Inout
            To_Close => True);
      end if;
   end Connect;

   function Connect (Peer : End_Point) return File_Type is
   begin
      return Result : File_Type do
         Connect (Result, Peer);
      end return;
   end Connect;

   package body End_Points is

      function Reference (
         Object : End_Point)
         return not null access C.ws2tcpip.struct_addrinfoW_ptr is
      begin
         return Object.Data'Unrestricted_Access;
      end Reference;

      overriding procedure Finalize (Object : in out End_Point) is
      begin
         C.ws2tcpip.FreeAddrInfoW (Object.Data);
      end Finalize;

   end End_Points;

end Ada.Streams.Stream_IO.Sockets;
