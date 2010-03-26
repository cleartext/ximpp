package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.MicroBloggingMessageEvent;
	import com.cleartext.ximpp.models.MicroBloggingModel;
	import com.cleartext.ximpp.models.types.MessageStatusTypes;
	import com.cleartext.ximpp.models.utils.LinkUitls;
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
			"senderId INTEGER " +
			"originalSenderId INTEGER " +
			"rawxml TEXT);"; 
		
		public var messageId:int = -1;
		
		public var timestamp:Date;
		public var sender:String;
		
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
				dispatchEvent(new MicroBloggingMessageEvent(MicroBloggingMessageEvent.MESSAGE_STATUS_CHANGED, this));
			}
		}
		
		public var recipient:String;
		public var type:String;
		public var subject:String;
		public var plainMessage:String;
		public var displayMessage:String;
		
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
			newMessage.timestamp = new Date(obj["timestamp"]);
			newMessage.sender = obj["sender"];
			newMessage.recipient = obj["recipient"];
			newMessage.subject = obj["subject"];
			newMessage.plainMessage = obj["plainMessage"];
			newMessage.displayMessage = obj["displayMessage"];
			newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(obj["senderId"]);
			newMessage.mBlogOriginalSender = mBlogBuddies.getMicroBloggingBuddy(obj["originalSenderId"]);
			newMessage.rawXML = obj["rawXML"];
			
			return newMessage;
		}
		
		
		public function toDatabaseValues(userId:int):Array
		{
			var result:Array = [
				new DatabaseValue("userId", userId),
				new DatabaseValue("timestamp", timestamp),
				new DatabaseValue("sender", sender),
				new DatabaseValue("recipient", recipient),
				new DatabaseValue("type", type),
				new DatabaseValue("subject", subject),
				new DatabaseValue("plainMessage", plainMessage),
				new DatabaseValue("displayMessage", displayMessage),
				new DatabaseValue("rawxml", rawXML),
				];

			if(mBlogSender)
				result.push(new DatabaseValue("senderId", mBlogSender.microBloggingBuddyId));

			if(mBlogOriginalSender)
				result.push(new DatabaseValue("originalSenderId", mBlogOriginalSender.microBloggingBuddyId));
			
			return result;
		}
		
		public static function createFromStanza(stanza:Object, mBlogBuddies:MicroBloggingModel):Message
		{
			var newMessage:Message = new Message();
			newMessage.timestamp = new Date();

			newMessage.sender = stanza.from.getBareJID();
			newMessage.recipient = stanza.to.getBareJID();
			newMessage.type = stanza.type;
			newMessage.subject = stanza.subject;
			newMessage.plainMessage = stanza.body;
			newMessage.rawXML = stanza.xml.toXMLString();
			
			if(stanza.html && newMessage.sender == "twitter.cleartext.com")
			{
				var regexp:RegExp = new RegExp("<img src=\"(.*?)\"[\\s\\S]*?<a.*?>(.*?)<[\\s\\S]*?\\((.*?)\\): ([\\s\\S]*?)</span>", "ig");
				var result:Array = regexp.exec(stanza.html);

				if(result && result.length > 0)
				{
					newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(result[3], "twitter.cleartext.com", result[2], result[1]);
					var messageString:String = String(result[4]);
					newMessage.plainMessage = messageString;
					
					// remove <a/> tags
					messageString = messageString.replace(new RegExp("\\s*<a.*?>(.*?)</a>\\s*", "ig"), " $1 ");
					// create links
					messageString = LinkUitls.createLinks(messageString);
					// find # links avoiding the # already in font color tags
					var regExp2:RegExp = new RegExp("((?<!<FONT COLOR=\")#|^#)(\\w+?)\\b", "ig");
					messageString = messageString.replace(regExp2, LinkUitls.getStartTag() + "http://twitter.com/search?q=%23$2\">$&" + LinkUitls.endTag);
					// find @ links
					var regExp1:RegExp = new RegExp("@(\\w+?)\\b", "ig");
					messageString = messageString.replace(regExp1, LinkUitls.getStartTag() + "http://twitter.com/$1\">$&" + LinkUitls.endTag);
					
					newMessage.displayMessage = messageString;
					return newMessage;
				}
			}
			
			newMessage.displayMessage = LinkUitls.createLinks(newMessage.plainMessage);
			return newMessage;
		}
		
	}
}