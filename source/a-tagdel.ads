pragma License (Unrestricted);
--  extended package for Delphi-like interface delegation
private with System;
package Ada.Tags.Delegating is

   generic
      type T (<>) is abstract tagged limited private;
      type I is limited interface;
      with function Get (Object : not null access T'Class)
         return access I'Class;
   package Implements is
   private
      function F (Object : System.Address) return System.Address;
   end Implements;

private

   function Get_Delegation (Object : System.Address; Interface_Tag : Tag)
      return System.Address;

   procedure Register_Delegation (
      T : Tag;
      Interface_Tag : Tag;
      Get : not null access function (Object : System.Address)
         return System.Address);

end Ada.Tags.Delegating;
