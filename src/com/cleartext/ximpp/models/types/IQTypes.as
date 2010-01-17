package com.cleartext.ximpp.models.types
{
	public class IQTypes
	{
		public static const GET:String = "get";
		public static const SET:String = "set";
		public static const RESULT:String = "result";
		public static const ERROR:String = "error";
		
		public static const GET_ROSTER:XML = <query xmlns='jabber:iq:roster'/>;
		public static const GET_USERS_VCARD:XML = <vCard xmlns='vcard-temp'/>;
		
		public static function modifyRoster(jid:String, remove:Boolean=false):XML
		{
			var result:XML = <query xmlns="jabber:iq:roster" />;
			var item:XML = <item jid={jid} />
			if(remove)
				item.@subscription = SubscriptionTypes.REMOVE;
			
			result.appendChild(item);
			return result;
		}
	}
}