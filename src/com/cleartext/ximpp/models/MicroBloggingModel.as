package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.MicroBloggingBuddy;
	
	import flash.utils.Dictionary;
	
	public class MicroBloggingModel
	{
		[Autowire]
		public var database:DatabaseModel;
		
		private var buddiesById:Dictionary = new Dictionary();
		
		public function MicroBloggingModel()
		{
		}

		public function getMicroBloggingBuddy(idOrUserName:Object, gatewayJid:String=null, displayName:String=null, avatarUrl:String=null, jid:String=null, avatarHash:String=null):MicroBloggingBuddy
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
				
				buddy.addEventListener(BuddyEvent.CHANGED, buddyChangedHandler);
			}
			
			if(displayName)
				buddy.displayName = displayName;
			
			if(avatarUrl)
				buddy.setAvatarUrl(avatarUrl);
				
			if(jid || avatarHash)
				buddy.setJidAndHash(jid, avatarHash);

			return buddy;
		}
		
		public function getBuddyByJid(jid:String):MicroBloggingBuddy
		{
			for each(var buddy:MicroBloggingBuddy in buddiesById)
				if(buddy.jid == jid)
					return buddy;
			return null;
		}
		
		public function buddyChangedHandler(event:BuddyEvent):void
		{
			var buddy:MicroBloggingBuddy = event.target as MicroBloggingBuddy;
			database.saveMicroBloggingBuddy(buddy);
		}
	}
}