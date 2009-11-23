package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.EventDispatcher;

	public class GlobalSettings extends EventDispatcher implements IXimppValueObject
	{
		public static const CREATE_GLOBAL_SETTINGS_TABLE:String =
				"CREATE TABLE IF NOT EXISTS globalSettings (" +
				"settingId INTEGER PRIMARY KEY AUTOINCREMENT, " +
				"autoConnect BOOLEAN DEFAULT True, " +
				"urlShortener TEXT DEFAULT '" + UrlShortener.types[0] + "', " +
				"timelineTopDown BOOLEAN DEFAULT True, " +
				"chatTopDown BOOLEAN DEFAULT False, " +
				"animateBuddyList BOOLEAN DEFAULT True, " +
				"numChatMessages INTEGER DEFAULT 150, " +
				"numTimelineMessages INTEGER DEFAULT 250, " +
				"openChats TEXT, " + 
				"buddySortMethod TEXT DEFAULT 'last active', " +
				"timelineSortMethod TEXT DEFAULT 'received', " +
				"userId INTEGER DEFAULT 1);";
		
		public function GlobalSettings()
		{
			super();
		}
		
		public var autoConnect:Boolean;
		public var urlShortener:String;
		public var timelineTopDown:Boolean;
		public var chatTopDown:Boolean;
		public var animateBuddyList:Boolean ;
		public var numChatMessages:uint;
		public var numTimelineMessages:uint;

		public function fill(obj:Object):void
		{
			this.autoConnect = obj["autoConnect"];
			this.urlShortener = obj["urlShortener"];
			this.timelineTopDown = obj["timelineTopDown"];
			this.chatTopDown = obj["chatTopDown"];
			this.animateBuddyList = obj["animateBuddyList"];
			this.numChatMessages = obj["numChatMessages"];
			this.numTimelineMessages = obj["numTimelineMessages"];
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("autoConnect", autoConnect),
				new DatabaseValue("urlShortener", urlShortener),
				new DatabaseValue("timelineTopDown", timelineTopDown),
				new DatabaseValue("chatTopDown", chatTopDown),
				new DatabaseValue("animateBuddyList", animateBuddyList),
				new DatabaseValue("numChatMessages", numChatMessages),
				new DatabaseValue("numTimelineMessages", numTimelineMessages),
				new DatabaseValue("userId", userId)];
		}
		
		override public function toString():String
		{
			return null;
		}
		
		public function toXML():XML
		{
			return null;
		}
	}
}