package com.cleartext.esm.models
{
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.models.valueObjects.MicroBloggingBuddy;
	import com.cleartext.esm.models.valueObjects.UserAccount;
	
	import flash.utils.Dictionary;
	
	public class MicroBloggingModel1
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire]
		public var database:DatabaseModel;
		
		[Autowire]
		public var xmpp:XMPPModel;
		
		[Bindable]
		[Autowire (bean="settings", property="userAccount")]
		public var userAccount:UserAccount;
		
		private var buddiesById:Dictionary = new Dictionary();
		
		public function MicroBloggingModel1()
		{
		}

		public function getMicroBloggingBuddy(idOrUserName:Object, gatewayJid:String=null, profileUrl:String=null, displayName:String=null):MicroBloggingBuddy
		{
			if(!idOrUserName)
				return null;
			
			var buddy:MicroBloggingBuddy;

			if(!gatewayJid)
			{
				var dbId:int = idOrUserName as int;
				if(dbId > 0 && buddiesById.hasOwnProperty(dbId))
					buddy = buddiesById[dbId];
			}
			else
			{
				var userName:String = idOrUserName as String;
				for each(var b:MicroBloggingBuddy in buddiesById)
				{
					if(b.userName == userName && b.gatewayJid == gatewayJid)
					{
						buddy = b;
						break;
					}
				}
			}
			
			if(!buddy)
			{
				buddy = database.getMicroBloggingBuddy(idOrUserName, gatewayJid);
				buddiesById[buddy.microBloggingBuddyId] = buddy;
				buddy.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangedHandler);
			}
			
			if(profileUrl != null)
				buddy.profileUrl = profileUrl;
							
			return buddy;
		}
		
		public function getBuddyByJid(jid:String):MicroBloggingBuddy
		{
			for each(var buddy:MicroBloggingBuddy in buddiesById)
				if(buddy.jid == jid)
					return buddy;
			return null;
		}
		
		private function buddyChangedHandler(event:HasAvatarEvent):void
		{
			var buddy:MicroBloggingBuddy = event.target as MicroBloggingBuddy;
			database.saveMicroBloggingBuddy(buddy);
		}
	}
}