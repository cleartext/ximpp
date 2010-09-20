package com.cleartext.esm.models.valueObjects
{
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	public class Message extends SproutListDataBase
	{
		public var sortBySentDate:Boolean;
		
		public static const CREATE_MESSAGES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS messages(" +
			"messageId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"sender TEXT, " +
			"recipient TEXT, " +
			"type TEXT, " +
			"subject TEXT, " +
			"plainMessage TEXT, " +
			"displayMessage TEXT, " + 
			"senderId INTEGER, " +
			"originalSenderId INTEGER, " +
			"rawxml TEXT," +
			"sentTimestamp NUMERIC, " +
			"receivedTimestamp NUMERIC);";
		
		public static const TABLE_MODS:Array = [
			{name: "sentTimestamp", type: "NUMERIC"}, 
			{name: "receivedTimestamp", type: "NUMERIC"},
			{name: "searchTerms", type: "TEXT"},
			{name: "mBlogSenderJid", type: "TEXT"}
		];
		
		public var messageId:int = -1;
		
		public var sentTimestamp:Date;
		public var receivedTimestamp:Date;
		
		public var sender:String;
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var rawXML:String;
		public var mBlogSenderJid:String;
		public var displayMessage:String;
		public var groupChatSender:String;
		public var searchTerms:Array;
		
		private var _plainMessage:String;
		public function get plainMessage():String
		{
			return _plainMessage;
		}
		public function set plainMessage(value:String):void
		{
			if(plainMessage != value)
			{
				_plainMessage = value;
				searchString = (userAndDisplayName + " " + plainMessage).toLowerCase();
			}
		}
		
		private var _userAndDisplayName:String;
		public function get userAndDisplayName():String
		{
			return _userAndDisplayName;
		}
		public function set userAndDisplayName(value:String):void
		{
			if(value != userAndDisplayName)
			{
				_userAndDisplayName = value;
				searchString = (userAndDisplayName + " " + plainMessage).toLowerCase();
			}
		}
		
		// shortcut used for search filtering in the message list
		public var searchString:String;
		
		
		public function Message()
		{
			super();
		}
		
		public function get sortDate():Date
		{
			return (sortBySentDate) ? sentTimestamp : receivedTimestamp;
		}
		
		public static function createFromDB(obj:Object):Message
		{
			var newMessage:Message = new Message();
			
			newMessage.messageId = obj["messageId"];
			newMessage.sender = obj["sender"];
			newMessage.recipient = obj["recipient"];
			newMessage.subject = obj["subject"];
			newMessage.plainMessage = obj["plainMessage"];
			newMessage.displayMessage = obj["displayMessage"];
			newMessage.mBlogSenderJid = obj["mBlogSenderJid"];
			newMessage.rawXML = obj["rawXML"];
			var st:String = obj["searchTerms"];
			newMessage.searchTerms = (st) ? st.split(',') : [];
			newMessage.receivedTimestamp = new Date(Number(obj["receivedTimestamp"]));
			newMessage.sentTimestamp = new Date(Number(obj["sentTimestamp"]));

			return newMessage;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			var result:Array = [
				new DatabaseValue("userId", userId),
				new DatabaseValue("receivedTimestamp", receivedTimestamp.time),
				new DatabaseValue("sentTimestamp", sentTimestamp.time),
				new DatabaseValue("sender", sender),
				new DatabaseValue("recipient", recipient),
				new DatabaseValue("type", type),
				new DatabaseValue("subject", subject),
				new DatabaseValue("plainMessage", plainMessage),
				new DatabaseValue("displayMessage", displayMessage),
				new DatabaseValue("mBlogSenderJid", mBlogSenderJid)
				];

			if(rawXML)
				result.push(new DatabaseValue("rawxml", rawXML));
				
			if(searchTerms && searchTerms.length > 0)
				result.push(new DatabaseValue("searchTerms", searchTerms.join(',')));
			
			return result;
		}
	}
}