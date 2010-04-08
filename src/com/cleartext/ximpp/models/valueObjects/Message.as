package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.MicroBloggingMessageEvent;
	import com.cleartext.ximpp.models.MicroBloggingModel;
	import com.cleartext.ximpp.models.types.MessageStatusTypes;
	import com.cleartext.ximpp.models.utils.LinkUitls;
	import com.seesmic.as3.xmpp.MessageStanza;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import mx.utils.StringUtil;
	
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
		
		public var utcTimestamp:Date;
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
				new DatabaseValue("rawxml", rawXML),
				];

			if(mBlogSender)
				result.push(new DatabaseValue("senderId", mBlogSender.microBloggingBuddyId));

			if(mBlogOriginalSender)
				result.push(new DatabaseValue("originalSenderId", mBlogOriginalSender.microBloggingBuddyId));
			
			return result;
		}
		
		public static function createFromStanza(stanza:MessageStanza, mBlogBuddies:MicroBloggingModel):Message
		{
			var newMessage:Message = new Message();

			newMessage.sender = stanza.from.getBareJID();
			newMessage.recipient = stanza.to.getBareJID();
			newMessage.type = stanza.type;
			newMessage.subject = stanza.subject;
			newMessage.plainMessage = stanza.body;
			newMessage.rawXML = stanza.xml.toXMLString();
			var date:Date = stanza.utcTimestamp;
			newMessage.utcTimestamp = date;
			newMessage.timestamp = new Date(Date.UTC(date.fullYear, date.month, date.date, date.hours, date.minutes, date.seconds, date.milliseconds));
			
			var valuesSet:Boolean = false;

			var customTags:Array = stanza.customTags;
			if(customTags && customTags.length > 0)
			{
				for each(var x:XML in customTags)
				{
					for each(var n:Namespace in x.namespaceDeclarations())
					{
						if(n.uri == "http://cleartext.net/mblog")
						{
							var sBuddy:Object = x.*::buddy.(@type=="sender");

							if(sBuddy.*::jid != mBlogBuddies.userAccount.jid)
							{
								newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(
										String(sBuddy.*::userName), sBuddy.*::serviceJid, 
										sBuddy.*::displayName, sBuddy.*::avatar.(@type=='url'),
										sBuddy.*::jid, sBuddy.*::avatar.(@type=='hash'));
							}
							
							var osBuddy:Object = x.*::buddy.(@type=="originalSender");

							if(osBuddy)
							{
								newMessage.mBlogOriginalSender = mBlogBuddies.getMicroBloggingBuddy(
										String(osBuddy.*::userName), osBuddy.*::serviceJid, 
										osBuddy.*::displayName, osBuddy.*::avatar.(@type=='url'),
										osBuddy.*::jid, osBuddy.*::avatar.(@type=='hash'));
							}
							valuesSet = true;
						}
					}
				}
			}
			
			if(!valuesSet && stanza.html)
			{
				var regexpString:String =
					"<img src=('|\")" + 		// open img tag with src=" or src='
					"(.*?)" + 					// image url - result[2]
					"\\1" +			 			// the closing " or '
					"[\\s\\S]*?" + 				// a lazy amount of any chars
					"<a.*?>" + 					// a open a tag with any kind of href 
					"(.*?)<" + 					// the text within the a tag - the display name - result[3]
					"[\\s\\S]*?" + 				// a lazy amount of any chars
					"\\((.*?)\\): " + 			// text within (): - the user id - result[4]
					"([\\s\\S]*?)" + 			// a lazy amount of any chars - the message - result[5]
					"</span>";					// the closing span tag
				
				var regexp:RegExp = new RegExp(regexpString, "ig");
				var result:Array = regexp.exec(stanza.html);

				if(result && result.length > 0)
				{
					newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(result[4], newMessage.recipient, result[3], result[2]);
					var messageString:String = String(result[5]);
					newMessage.plainMessage = messageString;
					
					// remove all html tags tags
					messageString = messageString.replace(new RegExp("\\s*<([A-Z][A-Z0-9]*)\\b[^>]*>(.*?)</\\1>\\s*", "ig"), " $2 ");
					// create links
					messageString = LinkUitls.createLinks(messageString);
					// find # links avoiding the # already in font color tags
					var regExp2:RegExp = new RegExp("((?<!<FONT COLOR=\")#|^#)(\\w+?)\\b", "ig");
					messageString = messageString.replace(regExp2, LinkUitls.getStartTag() + "http://twitter.com/search?q=%23$2\">$&" + LinkUitls.endTag);
					// find @ links
					var regExp1:RegExp = new RegExp("@(\\w+?)\\b", "ig");
					messageString = messageString.replace(regExp1, LinkUitls.getStartTag() + "http://twitter.com/$1\">$&" + LinkUitls.endTag);
					
					messageString = StringUtil.trim(messageString);
					
					newMessage.displayMessage = messageString;
					return newMessage;
				}
			}
			
			newMessage.displayMessage = LinkUitls.createLinks(newMessage.plainMessage);
			return newMessage;
		}
	}
}