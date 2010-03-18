package com.cleartext.ximpp.models.types
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	public class IQTypes
	{
		public static const GET:String = "get";
		public static const SET:String = "set";
		public static const RESULT:String = "result";
		public static const ERROR:String = "error";
		
		public static const GET_ROSTER:XML = <query xmlns='jabber:iq:roster'/>;
		public static const GET_USERS_VCARD:XML = <vCard xmlns='vcard-temp'/>;
		
		public static function addRemoveRosterItem(jid:String, nickName:String=null, groups:Array=null, remove:Boolean=false):XML
		{
			var result:XML = <query xmlns="jabber:iq:roster" />;
			var item:XML = <item jid={jid} />
			
			if(nickName)
				item.@name = nickName;
			
			if(remove)
				item.@subscription = SubscriptionTypes.REMOVE;

			if(groups)
				for each(var group:String in groups)
					item.appendChild(<group>{group}</group>);
			
			result.appendChild(item);
			return result;
		}
		
		public static function modifyRosterItem(buddy:Buddy):XML
		{
			var result:XML = <query xmlns="jabber:iq:roster" />;
			var item:XML = <item jid={buddy.jid} subscription={buddy.subscription}/>
			if(buddy.nickName != buddy.jid)
				item.@name = buddy.nickName;
			
			for each(var group:String in buddy.groups)
				item.appendChild(<group>{group}</group>);
			
			result.appendChild(item);
			return result;
		}
	}
}
