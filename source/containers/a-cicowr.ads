pragma License (Unrestricted);
--  implementation package
package Ada.Containers.Inside.Copy_On_Write is
   pragma Preelaborate;

   type Container;

   type Data is limited record
      Follower : access Container; --  first container is owner
   end record;

   type Data_Access is access Data;

   type Container is record
      Data : Data_Access;
      Next_Follower : access Container;
   end record;

   procedure Follow (
      Target : not null access Container;
      Data : not null Data_Access);
   procedure Unfollow (
      Target : not null access Container);

   procedure Unique (
      Target : not null access Container;
      To_Update : Boolean;
      Capacity : Count_Type;
      Allocate : not null access procedure (Target : out Data_Access);
      Copy : not null access procedure (
         Target : out Data_Access;
         Source : not null Data_Access;
         Capacity : Count_Type));

   procedure Adjust (
      Target : not null access Container);

   procedure Assign (
      Target : not null access Container;
      Source : not null access constant Container;
      Free : not null access procedure (Object : in out Data_Access));
   procedure Clear (
      Target : not null access Container;
      Free : not null access procedure (Object : in out Data_Access));
   function Copy (
      Source : not null access constant Container;
      Capacity : Count_Type;
      Copy : not null access procedure (
         Target : out Data_Access;
         Source : not null Data_Access;
         Capacity : Count_Type))
      return Container;
   procedure Move (
      Target : not null access Container;
      Source : not null access Container;
      Free : not null access procedure (Object : in out Data_Access));

end Ada.Containers.Inside.Copy_On_Write;