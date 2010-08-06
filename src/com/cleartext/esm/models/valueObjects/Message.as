package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.models.MicroBloggingModel;
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
			{name: "searchTerms", type: "TEXT"}
		];
		
		public var messageId:int = -1;
		
		public var sentTimestamp:Date;
		public var receivedTimestamp:Date;
		
		public var sender:String;
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var plainMessage:String;
		public var displayMessage:String;
		public var groupChatSender:String;
		public var searchTerms:Array;
		
		public var rawXML:String;
		
		public var mBlogSender:MicroBloggingBuddy;
		public var mBlogOriginalSender:MicroBloggingBuddy;
		
		public function Message()
		{
			super();
		}
		
		public function get sortDate():Date
		{
			return (sortBySentDate) ? sentTimestamp : receivedTimestamp;
		}
		
		public static function createFromDB(obj:Object, mBlogBuddies:MicroBloggingModel):Message
		{
			var newMessage:Message = new Message();
			
			newMessage.messageId = obj["messageId"];
			newMessage.sender = obj["sender"];
			newMessage.recipient = obj["recipient"];
			newMessage.subject = obj["subject"];
			newMessage.plainMessage = obj["plainMessage"];
			newMessage.displayMessage = obj["displayMessage"];
			newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(obj["senderId"]);
			newMessage.mBlogOriginalSender = mBlogBuddies.getMicroBloggingBuddy(obj["originalSenderId"]);
			newMessage.rawXML = obj["rawXML"];
			var st:String = obj["searchTerms"];
			newMessage.searchTerms = (st) ? st.split(',') : [];
			
			if(obj["timestamp"])
			{
				newMessage.receivedTimestamp = new Date(obj["timestamp"]);
				newMessage.sentTimestamp = new Date(obj["timestamp"]);
			}
			else
			{
				newMessage.receivedTimestamp = new Date(Number(obj["receivedTimestamp"]));
				newMessage.sentTimestamp = new Date(Number(obj["sentTimestamp"]));
			}

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
				];

			if(rawXML)
				result.push(new DatabaseValue("rawxml", rawXML));
				
			if(mBlogSender)
				result.push(new DatabaseValue("senderId", mBlogSender.microBloggingBuddyId));

			if(mBlogOriginalSender)
				result.push(new DatabaseValue("originalSenderId", mBlogOriginalSender.microBloggingBuddyId));
			
			if(searchTerms && searchTerms.length > 0)
				result.push(new DatabaseValue("searchTerms", searchTerms.join(',')));
			
			return result;
		}
	}
}