package com.cleartext.ximpp.models.valueObjects
{
	public class Status
	{
		// unavailable
		public static const OFFLINE:String = "offline";
		// available
		public static const AVAILABLE:String = "available";
		public static const AWAY:String = "away";
		public static const BUSY:String = "busy";
		public static const EXTENDED_AWAY:String = "inactive";
		public static const UNKNOWN:String = "unknown";
		
		// status's the user can choose from
		public static const USER_TYPES:Array = [OFFLINE, AVAILABLE, BUSY, AWAY];
		
		// other status'
		public static const CONNECTING:String = "connecting...";
		public static const ERROR:String = "error";
		
		// find a status value from what the xmpp libray tells us
		public static function fromShow(show:String):String
		{
			switch(show)
			{
				case "unavailable" : return OFFLINE;
				case "" : return AVAILABLE;
				case "available" : return AVAILABLE;
				case "chat" : return AVAILABLE; 
				case "away" : return AWAY;
				case "dnd" : return BUSY;
				case "xa" : return EXTENDED_AWAY;
				default : return UNKNOWN;
			}
		}
		
		// generate something the xmpp library will understand
		public static function toShow(status:String):String
		{
			switch(status)
			{
				case OFFLINE : return "unavailable";
				case AVAILABLE : return "chat";
				case AWAY : return "away";
				case BUSY : return "dnd";
				case EXTENDED_AWAY : return "xa";
				default : return "";
			}
		}
	}
}