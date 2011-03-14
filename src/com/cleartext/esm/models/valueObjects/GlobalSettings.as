package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.ApplicationEvent;
	import com.cleartext.esm.models.types.AvatarDisplayTypes;
	import com.cleartext.esm.models.types.BuddySortTypes;
	
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import org.swizframework.Swiz;

	public class GlobalSettings extends EventDispatcher
	{
		[Bindable]
		public var buddySortMethod:String = BuddySortTypes.STATUS;
		
		[Bindable]
		public var sortBySentDate:Boolean = true;
		
		[Bindable]
		public var autoShortenUrls:Boolean = true;

		[Bindable]
		public var animateBuddyList:Boolean = true;

		[Bindable]
		public var animateMessageList:Boolean = true;

		[Bindable]
		public var sendStatusToMicroBlogging:Boolean = false;

		[Bindable]
		public var showOfflineBuddies:Boolean = true;
				
		public var urlShortener:String = UrlShortener.types[0];
		public var numChatMessages:uint = 200;
		public var numTimelineMessages:uint = 200;
		public var awayTimeout:int = 5;

		public var autoConnect:Boolean = false;
		public var playSounds:Boolean = true;
		public var checkUrls:Boolean = true;
		public var showAvatars:Boolean = true;
		public var showNicknames:Boolean = false;
		public var rosterVersion:String = "";
		
		public function GlobalSettings()
		{
			super();
		}
		
		public function load():void
		{
			var prefDir:File = File.applicationStorageDirectory;
			
			var file:File = new File(prefDir.nativePath + "/globalSettings.xml");
			if(file.exists)
			{
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.READ);
				var xml:XML = new XML(fileStream.readUTFBytes(fileStream.bytesAvailable));

				if(BuddySortTypes.types.indexOf(xml.buddySortMethod) != -1)
					buddySortMethod = xml.buddySortMethod;

				if(xml.sortBySentDate)
					sortBySentDate = xml.sortBySentDate == "true";
	
				if(xml.autoShortenUrls)
					autoShortenUrls = xml.autoShortenUrls == "true";

				if(xml.animateBuddyList)
					animateBuddyList = xml.animateBuddyList == "true";

				if(xml.animateMessageList)
					animateMessageList = xml.animateMessageList == "true";

				if(xml.sendStatusToMicroBlogging)
					sendStatusToMicroBlogging = xml.sendStatusToMicroBlogging == "true";

				if(UrlShortener.types.indexOf(xml.urlShortener) != -1)
					urlShortener = xml.urlShortener;
	
				if(xml.numChatMessages > 1)
					numChatMessages = xml.numChatMessages;
	
				if(xml.numTimelineMessages > 1)
					numTimelineMessages = xml.numTimelineMessages;
	
				if(xml.awayTimeout > 1)
					awayTimeout = Math.min(1440, xml.awayTimeout);
				
				if(xml.autoConnect)
					autoConnect = xml.autoConnect == "true";

				if(xml.showOfflineBuddies)
					showOfflineBuddies = xml.showOfflineBuddies != "false";

				if(xml.playSounds)
					playSounds = xml.playSounds != "false";

				if(xml.checkUrls)
					checkUrls = xml.checkUrls != "false";
				
				if(xml.showAvatars)
					showAvatars = xml.showAvatars != "false";
			
				if(xml.showNicknames)
					showNicknames = xml.showNicknames == "true";
				
				if(xml.rosterVersion)
					rosterVersion = xml.rosterVersion;
				else
					rosterVersion = "";
				
				fileStream.close();
			}
			save();
			Swiz.dispatchEvent(new ApplicationEvent(ApplicationEvent.REFRESH_AVATAR_TABS));
		}
		
		public function save():void
		{
			var prefDir:File = File.applicationStorageDirectory;
			
			var file:File = prefDir.resolvePath("globalSettings.xml");
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			
			var xml:XML =
				<globalSettings>
					<buddySortMethod>{buddySortMethod}</buddySortMethod>
					<sortBySentDate>{sortBySentDate}</sortBySentDate>
					<autoShortenUrls>{autoShortenUrls}</autoShortenUrls>
					<animateBuddyList>{animateBuddyList}</animateBuddyList>
					<animateMessageList>{animateMessageList}</animateMessageList>
					<sendStatusToMicroBlogging>{sendStatusToMicroBlogging}</sendStatusToMicroBlogging>
					<urlShortener>{urlShortener}</urlShortener>
					<numChatMessages>{numChatMessages}</numChatMessages>
					<numTimelineMessages>{numTimelineMessages}</numTimelineMessages>
					<awayTimeout>{awayTimeout}</awayTimeout>
					<autoConnect>{autoConnect}</autoConnect>
					<showOfflineBuddies>{showOfflineBuddies}</showOfflineBuddies>
					<playSounds>{playSounds}</playSounds>
					<checkUrls>{checkUrls}</checkUrls>
					<showAvatars>{showAvatars}</showAvatars>
					<showNicknames>{showNicknames}</showNicknames>
					<rosterVersion>{rosterVersion}</rosterVersion>
				</globalSettings>;

			fileStream.writeUTFBytes(xml.toXMLString());
			fileStream.close();
		}
	}
}