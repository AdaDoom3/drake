pragma License (Unrestricted);
--  extended unit
with Ada.Characters.Conversions;
with Ada.Strings.Maps;
package Ada.Strings.Functions.Maps is
   new Generic_Maps (
      Expanding => 6, -- System.UTF_Conversions.UTF_8_Max_Length
      Put => Characters.Conversions.Put,
      Get => Characters.Conversions.Get,
      Get_Reverse => Characters.Conversions.Get_Reverse,
      Character_Set => Strings.Maps.Character_Set,
      Is_In => Strings.Maps.Overloaded_Is_In,
      Character_Mapping => Strings.Maps.Character_Mapping,
      Value => Strings.Maps.Overloaded_Value);
pragma Preelaborate (Ada.Strings.Functions.Maps);
