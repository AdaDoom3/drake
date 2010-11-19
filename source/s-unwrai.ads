pragma License (Unrestricted);
pragma Compiler_Unit;
package System.Unwind.Raising is
   pragma Preelaborate;

   --  (s-stalib.ads)
   Local_Partition_ID : Natural := 0;

   --  equivalent to Raise_With_Location_And_Msg (a-except-2005.adb)
   procedure Raise_Exception (
      E : not null Standard_Library.Exception_Data_Ptr;
      File : access constant Character := null;
      Line : Integer := 0;
      Message : String := "");
   pragma No_Return (Raise_Exception);

   --  equivalent to Raise_From_Signal_Handler (a-except-2005.adb)
   procedure Raise_From_Signal_Handler (
      E : not null Standard_Library.Exception_Data_Ptr;
      File : access constant Character := null;
      Line : Integer := 0;
      Message : String := "")
      renames Raise_Exception;
   --  From_Signal_Handler should be True, but unused it, currently...

   --  required to reraise by compiler (a-except-2005.adb)
   procedure Reraise (X : Exception_Occurrence);
   pragma No_Return (Reraise);

   --  for System.Finalization_Implementation (a-except-2005.adb)
   procedure Raise_From_Controlled_Operation (X : Exception_Occurrence);
   pragma No_Return (Raise_From_Controlled_Operation);

   --  shortcut required by compiler (a-except-2005.adb)

   procedure rcheck_00 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_00);
   pragma Export (C, rcheck_00, "__gnat_rcheck_00");

   procedure rcheck_02 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_02);
   pragma Export (C, rcheck_02, "__gnat_rcheck_02");

   procedure rcheck_03 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_03);
   pragma Export (C, rcheck_03, "__gnat_rcheck_03");

   procedure rcheck_04 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_04);
   pragma Export (C, rcheck_04, "__gnat_rcheck_04");

   procedure rcheck_05 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_05);
   pragma Export (C, rcheck_05, "__gnat_rcheck_05");

   procedure rcheck_06 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_06);
   pragma Export (C, rcheck_06, "__gnat_rcheck_06");

   procedure rcheck_07 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_07);
   pragma Export (C, rcheck_07, "__gnat_rcheck_07");

   procedure rcheck_10 (File : access constant Character; Line : Integer);
   pragma No_Return (rcheck_10);
   pragma Export (C, rcheck_10, "__gnat_rcheck_10");

   procedure Overflow (
      File : access constant Character := null;
      Line : Integer := 0)
      renames rcheck_10;

   procedure rcheck_12 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_12);
   pragma Export (C, rcheck_12, "__gnat_rcheck_12");

   procedure rcheck_13 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_13);
   pragma Export (C, rcheck_13, "__gnat_rcheck_13");

   procedure rcheck_15 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_15);
   pragma Export (C, rcheck_15, "__gnat_rcheck_15");

   procedure rcheck_20 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_20);
   pragma Export (C, rcheck_20, "__gnat_rcheck_20");

   procedure rcheck_21 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_21);
   pragma Export (C, rcheck_21, "__gnat_rcheck_21");

   procedure rcheck_23 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_23);
   pragma Export (C, rcheck_23, "__gnat_rcheck_23");

   procedure rcheck_31 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_31);
   pragma Export (C, rcheck_31, "__gnat_rcheck_31");

   procedure rcheck_33 (File : not null access Character; Line : Integer);
   pragma No_Return (rcheck_33);
   pragma Export (C, rcheck_33, "__gnat_rcheck_33");

   --  excluding code range
   function AAA return Address;
   function ZZZ return Address;

end System.Unwind.Raising;
