package com.cleartext.ximpp.models.valueObjects
{
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	public class Message extends SproutListDataBase implements IXimppValueObject
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
			"body TEXT, " +
			"rawxml TEXT);";
		
		public var messageId:int = -1;
		public var timestamp:Date = new Date();
		public var sender:String;
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var body:String;
		public var rawXML:String;
		
		public function Message()
		{
			super();
		}
		
		public function fill(obj:Object):void
		{
			messageId = obj["messageId"];
			timestamp = new Date(obj["timestamp"]);
			sender = obj["sender"];
			recipient = obj["recipient"];
			type = obj["type"];
			subject = obj["subject"];
			body = obj["body"];
			rawXML = obj["rawXML"];
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("timestamp", timestamp),
				new DatabaseValue("sender", sender),
				new DatabaseValue("recipient", recipient),
				new DatabaseValue("type", type),
				new DatabaseValue("subject", subject),
				new DatabaseValue("body", body),
				new DatabaseValue("rawxml", rawXML),
				];
			
		}
		
		public static function createFromStanza(stanza:Object):Message
		{
			var newMessage:Message = new Message();
			newMessage.timestamp = new Date();
			
			newMessage.sender = stanza.from.getBareJID();
			newMessage.recipient = stanza.to.getBareJID();
			newMessage.type = stanza.type;
			newMessage.subject = stanza.subject;
			newMessage.body = stanza.body;
			
			return newMessage;
		}
		
		override public function toString():String
		{
			return "";
		}
		
		public function toXML():XML
		{
			return null;
		}
	}
}