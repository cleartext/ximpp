package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.MicroBloggingModel;
	import com.cleartext.ximpp.models.types.MessageStatusTypes;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	public class Message extends SproutListDataBase
	{
		public static const CREATE_MESSAGES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS messages (" +
			"messageId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"timestamp DATE, " +
			"sender TEXT, " +
			"recipient TEXT, " +
			"type TEXT, " +
			"subject TEXT, " +
			"plainMessage TEXT, " +
			"displayMessage TEXT, " + 
			"senderId INTEGER, " +
			"originalSenderId INTEGER, " +
			"rawxml TEXT);"; 
		
		public var messageId:int = -1;
		
		public var utcTimestamp:Date;
		public var timestamp:Date;
		public var sender:String;
		
		public function get time():Number
		{
			if(utcTimestamp)
				return utcTimestamp.time;
			return 0;
		}
		
		private var _status:String = MessageStatusTypes.UNKNOWN;
		[Bindable(event="messageStatusChanged")]
		public function get status():String
		{
			return _status;
		}
		public function set status(value:String):void
		{
			if(_status != value)
			{
				_status = value;
//				dispatchEvent(new MicroBloggingMessageEvent(MicroBloggingMessageEvent.MESSAGE_STATUS_CHANGED, this));
			}
		}
		
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var plainMessage:String;
		public var displayMessage:String;
		public var groupChatSender:String;
		
		public var rawXML:String;
		
		public var mBlogSender:MicroBloggingBuddy;
		public var mBlogOriginalSender:MicroBloggingBuddy;
		
		public function Message()
		{
			super();
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
			
			var date:Date = new Date(obj["timestamp"]);
			newMessage.utcTimestamp = date;
			newMessage.timestamp = new Date(Date.UTC(date.fullYear, date.month, date.date, date.hours, date.minutes, date.seconds, date.milliseconds));			

			return newMessage;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			var result:Array = [
				new DatabaseValue("userId", userId),
				new DatabaseValue("timestamp", utcTimestamp),
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
			
			return result;
		}
	}
}