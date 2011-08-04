pragma Check_Policy (Trace, Off);
with Ada.Unchecked_Conversion;
with System.Address_To_Constant_Access_Conversions;
with System.Address_To_Named_Access_Conversions;
with System.Debug;
with System.Soft_Links;
with C.unwind_pe;
package body System.Unwind.Handling is
   pragma Suppress (All_Checks);
   use type C.ptrdiff_t;
   use type C.signed_int;
   use type C.size_t;
   use type C.unsigned_char;
   use type C.unsigned_char_const_ptr;
   use type C.unsigned_int; --  _Unwind_Ptr is unsigned int or unsigned long
   use type C.unsigned_long;
   use type C.unsigned_long_long;
   use type C.void_ptr;
   use type C.unwind_pe.sleb128_t;

   function builtin_eh_return_data_regno (A1 : C.signed_int)
      return C.signed_int;
   pragma Import (Intrinsic, builtin_eh_return_data_regno,
      "__builtin_eh_return_data_regno");

   procedure Increment (p : in out C.unsigned_char_const_ptr);
   procedure Increment (p : in out C.unsigned_char_const_ptr) is
      package uchar_Conv is new Address_To_Constant_Access_Conversions (
         C.unsigned_char,
         C.unsigned_char_const_ptr);
   begin
      p := uchar_Conv.To_Pointer (uchar_Conv.To_Address (p) + 1);
   end Increment;

   function "+" (Left : C.unsigned_char_const_ptr; Right : C.ptrdiff_t)
      return C.unsigned_char_const_ptr;
   function "+" (Left : C.unsigned_char_const_ptr; Right : C.ptrdiff_t)
      return C.unsigned_char_const_ptr
   is
      package uchar_Conv is new Address_To_Constant_Access_Conversions (
         C.unsigned_char,
         C.unsigned_char_const_ptr);
   begin
      return uchar_Conv.To_Pointer (uchar_Conv.To_Address (Left)
         + Address (Right));
   end "+";

   function "<" (Left, Right : C.unsigned_char_const_ptr) return Boolean;
   function "<" (Left, Right : C.unsigned_char_const_ptr) return Boolean is
      package uchar_Conv is new Address_To_Constant_Access_Conversions (
         C.unsigned_char,
         C.unsigned_char_const_ptr);
   begin
      return uchar_Conv.To_Address (Left) < uchar_Conv.To_Address (Right);
   end "<";

   procedure Begin_Handler (GCC_Exception : GNAT_GCC_Exception_Access) is
   begin
      null;
   end Begin_Handler;

   procedure End_Handler (GCC_Exception : GNAT_GCC_Exception_Access) is
      Current : constant not null Exception_Occurrence_Access :=
         Soft_Links.Get_Task_Local_Storage.all.Current_Exception'Access;
      Prev : GNAT_GCC_Exception_Access := null;
      Iter : Exception_Occurrence_Access := Current;
   begin
      pragma Check (Trace, Debug.Put ("enter"));
      loop
         pragma Debug (Debug.Runtime_Error (
            Iter.Private_Data = Null_Address,
            "Iter.Private_Data = null"));
         declare
            package GGE_Conv is new Address_To_Named_Access_Conversions (
               GNAT_GCC_Exception,
               GNAT_GCC_Exception_Access);
            I_GCC_Exception : GNAT_GCC_Exception_Access :=
               GGE_Conv.To_Pointer (Iter.Private_Data);
         begin
            if I_GCC_Exception = GCC_Exception then
               if Prev = null then --  top(Current)
                  pragma Check (Trace, Debug.Put ("Prev = null"));
                  Iter := I_GCC_Exception.Next_Exception;
                  if Iter = null then
                     pragma Check (Trace, Debug.Put ("Iter = null"));
                     Current.Private_Data := Null_Address;
                  else
                     pragma Check (Trace, Debug.Put ("Iter /= null"));
                     Save_Occurrence_And_Private (Current.all, Iter.all);
                     pragma Check (Trace, Debug.Put ("free eo"));
                     Free (Iter);
                  end if;
               else
                  Prev.Next_Exception := I_GCC_Exception.Next_Exception;
                  pragma Check (Trace, Debug.Put ("free eo"));
                  Free (Iter);
               end if;
               pragma Check (Trace, Debug.Put ("free obj"));
               Free (I_GCC_Exception);
               exit; -- ok
            end if;
            pragma Debug (Debug.Runtime_Error (
               I_GCC_Exception.Next_Exception = null,
               "I_GCC_Exception.Next_Exception = null"));
            Prev := I_GCC_Exception;
            Iter := I_GCC_Exception.Next_Exception;
         end;
      end loop;
      pragma Check (Trace, Debug.Put ("leave"));
   end End_Handler;

   function Personality (
      ABI_Version : C.signed_int;
      Phases : C.unwind.Unwind_Action;
      Exception_Class : C.unwind.Unwind_Exception_Class;
      Exception_Object : access C.unwind.struct_Unwind_Exception;
      Context : access C.unwind.struct_Unwind_Context)
      return C.unwind.Unwind_Reason_Code
   is
      function Cast is new Ada.Unchecked_Conversion (
         C.unwind.struct_Unwind_Exception_ptr,
         C.unwind.Unwind_Word);
      function Cast is new Ada.Unchecked_Conversion (
         C.unwind.Unwind_Sword,
         C.unwind.Unwind_Word);
      GCC_Exception : GNAT_GCC_Exception;
      for GCC_Exception'Address use Exception_Object.all'Address;
      landing_pad : C.unwind.Unwind_Ptr;
      ttype_filter : C.unwind.Unwind_Sword; --  0 => finally, others => handler
   begin
      pragma Check (Trace, Debug.Put ("enter"));
      if ABI_Version /= 1 then
         pragma Check (Trace, Debug.Put ("ABI_Version /= 1"));
         return C.unwind.URC_FATAL_PHASE1_ERROR;
      end if;
      if Exception_Class = GNAT_Exception_Class
         and then C.unsigned_int (Phases) =
            (C.unwind.UA_CLEANUP_PHASE or C.unwind.UA_HANDLER_FRAME)
      then
         landing_pad := GCC_Exception.landing_pad;
         ttype_filter := GCC_Exception.ttype_filter;
         pragma Check (Trace, Debug.Put ("shortcut!"));
      else
         declare
            --  about region
            lsda : C.void_ptr;
            base : C.unwind.Unwind_Ptr;
            call_site_encoding : C.unsigned_char;
            call_site_table : C.unsigned_char_const_ptr;
            lp_base : aliased C.unwind.Unwind_Ptr;
            action_table : C.unsigned_char_const_ptr;
            ttype_encoding : C.unsigned_char;
            ttype_table : C.unsigned_char_const_ptr;
            ttype_base : C.unwind.Unwind_Ptr;
            --  about action
            table_entry : C.unsigned_char_const_ptr;
--          ttype_entry : C.unwind.Unwind_Ptr;
         begin
            if Context = null then
               pragma Check (Trace, Debug.Put ("Context = null"));
               return C.unwind.URC_CONTINUE_UNWIND;
            end if;
            lsda := C.unwind.Unwind_GetLanguageSpecificData (Context);
            if lsda = C.void_ptr (Null_Address) then
               pragma Check (Trace, Debug.Put ("lsda = null"));
               return C.unwind.URC_CONTINUE_UNWIND;
            end if;
            base := C.unwind.Unwind_GetRegionStart (Context);
            declare
               function Cast is new Ada.Unchecked_Conversion (
                  C.void_ptr,
                  C.unsigned_char_const_ptr);
               p : C.unsigned_char_const_ptr := Cast (lsda);
               tmp : aliased C.unwind_pe.uleb128_t;
               lpbase_encoding : C.unsigned_char;
            begin
               lpbase_encoding := p.all;
               Increment (p);
               if lpbase_encoding /= C.unwind_pe.DW_EH_PE_omit then
                  p := C.unwind_pe.read_encoded_value (
                     Context,
                     lpbase_encoding,
                     p,
                     lp_base'Access);
               else
                  lp_base := base;
               end if;
               ttype_encoding := p.all;
               Increment (p);
               if ttype_encoding /= C.unwind_pe.DW_EH_PE_omit then
                  p := C.unwind_pe.read_uleb128 (p, tmp'Access);
                  ttype_table := p + C.ptrdiff_t (tmp);
               else
                  pragma Check (Trace, Debug.Put (
                     "ttype_encoding = DW_EH_PE_omit"));
                  ttype_table := null; --  be access violation ?
               end if;
               ttype_base := C.unwind_pe.base_of_encoded_value (
                  ttype_encoding,
                  Context);
               call_site_encoding := p.all;
               Increment (p);
               call_site_table := C.unwind_pe.read_uleb128 (p, tmp'Access);
               action_table := call_site_table + C.ptrdiff_t (tmp);
            end;
            declare
               p : C.unsigned_char_const_ptr := call_site_table;
               ip_before_insn : aliased C.signed_int := 0;
               ip : C.unwind.Unwind_Ptr :=
                  C.unwind.Unwind_GetIPInfo (Context, ip_before_insn'Access);
            begin
               if ip_before_insn = 0 then
                  pragma Check (Trace, Debug.Put ("ip_before_insn = 0"));
                  ip := ip - 1;
               end if;
               loop
                  if not (p < action_table) then
                     pragma Check (Trace, Debug.Put (
                        "not (p < action_table)"));
                     return C.unwind.URC_CONTINUE_UNWIND;
                  end if;
                  declare
                     cs_start, cs_len, cs_lp : aliased C.unwind.Unwind_Ptr;
                     cs_action : aliased C.unwind_pe.uleb128_t;
                  begin
                     p := C.unwind_pe.read_encoded_value (
                        null,
                        call_site_encoding,
                        p,
                        cs_start'Access);
                     p := C.unwind_pe.read_encoded_value (
                        null,
                        call_site_encoding,
                        p,
                        cs_len'Access);
                     p := C.unwind_pe.read_encoded_value (
                        null,
                        call_site_encoding,
                        p,
                        cs_lp'Access);
                     p := C.unwind_pe.read_uleb128 (
                        p,
                        cs_action'Access);
                     if ip < base + cs_start then
                        pragma Check (Trace, Debug.Put (
                           "ip < base + cs_start"));
                        return C.unwind.URC_CONTINUE_UNWIND;
                     elsif ip < base + cs_start + cs_len then
                        if cs_lp /= 0 then
                           landing_pad := lp_base + cs_lp;
                        else
                           pragma Check (Trace, Debug.Put ("cs_lp = 0"));
                           return C.unwind.URC_CONTINUE_UNWIND;
                        end if;
                        if cs_action /= 0 then
                           table_entry := action_table +
                              C.ptrdiff_t (cs_action - 1);
                        else
                           table_entry := null;
                        end if;
                        exit;
                     end if;
                  end;
               end loop;
            end;
            if table_entry = null then
               ttype_filter := 0;
            else
               declare
                  p : C.unsigned_char_const_ptr := table_entry;
                  ar_filter, ar_disp : aliased C.unwind_pe.sleb128_t;
                  Dummy : C.unsigned_char_const_ptr;
                  pragma Unreferenced (Dummy);
               begin
                  loop
                     p := C.unwind_pe.read_sleb128 (p, ar_filter'Access);
                     Dummy := C.unwind_pe.read_sleb128 (p, ar_disp'Access);
                     if ar_filter = 0 then
                        ttype_filter := 0;
                        if ar_disp = 0 then
                           pragma Check (Trace, Debug.Put ("finally"));
                           exit;
                        end if;
                     elsif Exception_Class = GNAT_Exception_Class
                        and then ar_filter > 0
                     then
                        declare
                           function Cast is new Ada.Unchecked_Conversion (
                              Standard_Library.Exception_Data_Ptr,
                              C.unwind.Unwind_Ptr);
                           type Unwind_Ptr_Ptr is
                              access constant C.unwind.Unwind_Ptr;
                           function Cast is new Ada.Unchecked_Conversion (
                              Unwind_Ptr_Ptr,
                              C.unwind.Unwind_Ptr);
                           filter : constant C.ptrdiff_t :=
                              C.ptrdiff_t (ar_filter) *
                              C.ptrdiff_t (C.unwind_pe.size_of_encoded_value (
                                 ttype_encoding));
                           choice : aliased C.unwind.Unwind_Ptr;
                           is_handled : Boolean;
                        begin
                           Dummy := C.unwind_pe.read_encoded_value_with_base (
                              ttype_encoding,
                              ttype_base,
                              ttype_table + (-filter),
                              choice'Access);
                           is_handled := choice = Cast (GCC_Exception.Id)
                              or else choice = Cast (Others_Value'Access)
                              or else (choice = Cast (All_Others_Value'Access)
                                 and then
                                    GCC_Exception.Id.Not_Handled_By_Others);
                           if is_handled then
                              ttype_filter := C.unwind.Unwind_Sword (
                                 ar_filter);
--                            ttype_entry := choice;
                              pragma Check (Trace, Debug.Put (
                                 "handler is found"));
                              exit;
                           end if;
                        end;
                     else
                        pragma Check (Trace, Debug.Put ("ar_filter < 0"));
                        null;
                     end if;
                     if ar_disp = 0 then
                        pragma Check (Trace, Debug.Put ("ar_disp = 0"));
                        return C.unwind.URC_CONTINUE_UNWIND;
                     end if;
                     p := p + C.ptrdiff_t (ar_disp);
                  end loop;
               end;
            end if;
            if (C.unsigned_int (Phases) and C.unwind.UA_SEARCH_PHASE) /= 0 then
               if ttype_filter = 0 then --  cleanup
                  if Exception_Class = GNAT_Exception_Class then
                     GCC_Exception.N_Cleanups_To_Trigger :=
                        GCC_Exception.N_Cleanups_To_Trigger + 1; --  increment
                     pragma Check (Trace, Debug.Put ("Adjust_N_Cleanups_For"));
                  end if;
                  pragma Check (Trace, Debug.Put ("UA_SEARCH_PHASE, cleanup"));
                  return C.unwind.URC_CONTINUE_UNWIND;
               else
                  null; --  exception tracing (a-exextr.adb) is not implementd.
                  pragma Check (Trace, Debug.Put ("UA_SEARCH_PHASE, handler"));
                  --  shortcut for phase2
                  GCC_Exception.landing_pad := landing_pad;
                  GCC_Exception.ttype_filter := ttype_filter;
                  return C.unwind.URC_HANDLER_FOUND;
               end if;
            end if;
         end;
      end if;
      if Exception_Class = GNAT_Exception_Class
         and then ttype_filter = 0
      then
         GCC_Exception.N_Cleanups_To_Trigger :=
            GCC_Exception.N_Cleanups_To_Trigger - 1; --  decrement
         pragma Check (Trace, Debug.Put ("Adjust_N_Cleanups_For"));
      end if;
      pragma Check (Trace, Debug.Put ("unwind!"));
      C.unwind.Unwind_SetGR (
         Context,
         builtin_eh_return_data_regno (0),
         Cast (C.unwind.struct_Unwind_Exception_ptr (Exception_Object)));
      C.unwind.Unwind_SetGR (
         Context,
         builtin_eh_return_data_regno (1),
         Cast (ttype_filter));
      C.unwind.Unwind_SetIP (Context, landing_pad);
      pragma Check (Trace, Debug.Put ("leave"));
      return C.unwind.URC_INSTALL_CONTEXT;
   end Personality;

   procedure Save_Occurrence_And_Private (
      Target : out Exception_Occurrence;
      Source : Exception_Occurrence) is
   begin
      Unwind.Save_Occurrence_No_Private (Target, Source);
      Target.Private_Data := Source.Private_Data;
   end Save_Occurrence_And_Private;

end System.Unwind.Handling;
