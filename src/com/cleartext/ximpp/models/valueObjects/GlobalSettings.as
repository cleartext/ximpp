package com.cleartext.ximpp.models.valueObjects
{
	import flash.events.EventDispatcher;

	public class GlobalSettings extends EventDispatcher implements IXimppValueObject
	{
		public static const CREATE_GLOBAL_SETTINGS_TABLE:String =
				"CREATE TABLE IF NOT EXISTS globalSettings (" +
				"settingId INTEGER PRIMARY KEY AUTOINCREMENT, " +
				"autoConnect BOOLEAN DEFAULT False, " +
				"urlShortener TEXT DEFAULT '" + UrlShortener.types[0] + "', " +
				"timelineTopDown BOOLEAN DEFAULT True, " +
				"chatTopDown BOOLEAN DEFAULT False, " +
				"animateBuddyList BOOLEAN DEFAULT True, " +
				"numChatMessages INTEGER DEFAULT 150, " +
				"numTimelineMessages INTEGER DEFAULT 250, " +
				"openChats TEXT, " + 
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

		public static function createFromDB(obj:Object):GlobalSettings
		{
			var newGlobalSettings:GlobalSettings = new GlobalSettings();
			
			newGlobalSettings.autoConnect = obj["autoConnect"];
			newGlobalSettings.urlShortener = obj["urlShortener"];
			newGlobalSettings.timelineTopDown = obj["timelineTopDown"];
			newGlobalSettings.chatTopDown = obj["chatTopDown"];
			newGlobalSettings.animateBuddyList = obj["animateBuddyList"];
			newGlobalSettings.numChatMessages = obj["numChatMessages"];
			newGlobalSettings.numTimelineMessages = obj["numTimelineMessages"];
			
			return newGlobalSettings;
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
		
	}
}