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
			"publisher TEXT, " +
			"subscriber TEXT, " +
			"sender TEXT, " +
			"recipient TEXT, " +
			"type TEXT, " +
			"subject TEXT, " +
			"body TEXT, " +
			"htmlbody TEXT, " +
			"rawxml TEXT);";
		
		public var messageId:int = -1;
		public var timeStamp:Date = new Date();
		public var publisher:String;
		public var subscriber:String;
		public var sender:String;
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var body:String;
		public var htmlBody:String;
		public var rawXML:String;
		
		public function Message()
		{
			super();
		}
		
		public function fill(obj:Object):void
		{
			messageId = obj["messageId"];
			timeStamp = new Date(obj["timestamp"]);
			publisher = obj["publisher"];
			subscriber = obj["subscriber"];
			sender = obj["sender"];
			recipient = obj["recipient"];
			type = obj["type"];
			subject = obj["subject"];
			body = obj["body"];
			htmlBody = obj["htmlBody"];
			rawXML = obj["rawXML"];
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return null;
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