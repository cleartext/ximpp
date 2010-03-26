package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.types.BuddySortTypes;
	
	import flash.events.EventDispatcher;

	public class GlobalSettings extends EventDispatcher
	{
		public static const CREATE_GLOBAL_SETTINGS_TABLE:String =
				"CREATE TABLE IF NOT EXISTS globalSettings (" +
				"settingId INTEGER PRIMARY KEY AUTOINCREMENT, " + 
				"userId INTEGER DEFAULT 1, " +
				"xml TEXT);";
		
		public function GlobalSettings()
		{
			super();
		}
		
		public var autoConnect:Boolean;
		public var urlShortener:String;
		public var numChatMessages:uint;
		public var numTimelineMessages:uint;
		public var showOfflineBuddies:Boolean;
		
		[Bindable]
		public var autoShortenUrls:Boolean;

		[Bindable]
		public var animateBuddyList:Boolean;

		[Bindable]
		public var animateMessageList:Boolean;

		[Bindable]
		public var buddySortMethod:String;
		
		[Bindable]
		public var sendStatusToMicroBlogging:Boolean;

		public static function createFromDB(obj:Object):GlobalSettings
		{
			var newGlobalSettings:GlobalSettings = new GlobalSettings();

			// if we have values from the db, then use them, else
			// just set the default values
			if(obj["xml"] != null)
			{
				var xml:XML = new XML(obj["xml"] as String);
				newGlobalSettings.autoConnect = xml.@autoConnect == "true";
				newGlobalSettings.autoShortenUrls = xml.@autoShortenUrls == "true";
				newGlobalSettings.urlShortener = xml.@urlShortener;
				newGlobalSettings.animateBuddyList = xml.@animateBuddyList == "true";
				newGlobalSettings.animateMessageList = xml.@animateMessageList == "true";
				newGlobalSettings.numChatMessages = xml.@numChatMessages;
				newGlobalSettings.numTimelineMessages = xml.@numTimelineMessages;
				newGlobalSettings.showOfflineBuddies = xml.@showOfflineBuddies == "true";
				newGlobalSettings.sendStatusToMicroBlogging = xml.@sendStatusToMicroBlogging == "true";
				newGlobalSettings.buddySortMethod = xml.@buddySortMethod;
			}
			else
			{
				newGlobalSettings.autoConnect = true;
				newGlobalSettings.autoShortenUrls = true;
				newGlobalSettings.animateBuddyList = true;
				newGlobalSettings.animateMessageList = true;
				newGlobalSettings.showOfflineBuddies = true;
				newGlobalSettings.sendStatusToMicroBlogging = false;
			}
			
			// make sure that the values are set and are reasonable
			if(newGlobalSettings.numChatMessages < 1)
				newGlobalSettings.numChatMessages = 200;

			if(newGlobalSettings.numTimelineMessages < 1)
				newGlobalSettings.numTimelineMessages = 200;

			if(UrlShortener.types.indexOf(newGlobalSettings.urlShortener) == -1)
				newGlobalSettings.urlShortener = UrlShortener.types[0];

			if(BuddySortTypes.types.indexOf(newGlobalSettings.buddySortMethod) == -1)
				newGlobalSettings.buddySortMethod = BuddySortTypes.STATUS;

			return newGlobalSettings;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			var xml:XML = <globalSettings
				autoConnect={autoConnect} 
				urlShortener={urlShortener} 
				autoShortenUrls={autoShortenUrls}
				animateBuddyList={animateBuddyList} 
				animateMessageList={animateMessageList} 
				numChatMessages={numChatMessages} 
				numTimelineMessages={numTimelineMessages} 
				showOfflineBuddies={showOfflineBuddies} 
				sendStatusToMicroBlogging={sendStatusToMicroBlogging} 
				buddySortMethod={buddySortMethod}
				/>;
				
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("xml", xml.toXMLString())];
		}
				
		override public function toString():String
		{
			return null;
		}
		
	}
}