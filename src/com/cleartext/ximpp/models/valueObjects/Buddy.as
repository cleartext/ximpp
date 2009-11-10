package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	
	import flash.events.EventDispatcher;;
	
	/**
	 * @inheritDoc
	 */
	[Event(name="customStatusChanged", type="com.cleartext.ximpp.events.BuddyEvent")]
	
	[Bindable]
	public class Buddy extends EventDispatcher implements IXimppValueObject
	{
		public static const CREATE_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddies (" +
			"buddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"jid TEXT UNIQUE, " +
			"url TEXT, " +
			"isGateway BOOLEAN, " +
			"nickName TEXT, " +
			"groups TEXT, " +
			"emailAddress TEXT, " +
			"avatar TEXT, " +
			"broadcast BOOLEAN);";
		
		public var buddyId:int = -1;
		public var jid:String = "";
		public var resource:String = "";
		public var url:String = "";
		public var isGateway:Boolean = false;
		public var nickName:String = "";
		public var groups:Array;
		public var emailAddress:String = "";
		public var lastSeen:Date;
		public var status:String = "";
		private var _customStatus:String = "";
		public var showCustomStatus:Boolean = false;

		[Bindable (event="customStatusChanged")]
		public function get customStatus():String
		{
			return _customStatus;
		}
		public function set customStatus(value:String):void
		{
			if(_customStatus != value)
			{
				_customStatus = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CUSTOM_STATUS_CHANGED));
			}
		}
		public var broadcast:Boolean = false;
		
		public function fill(obj:Object):void
		{
			buddyId = obj["buddyId"];
			jid = obj["jid"];
			resource = obj["resource"];
			url = obj["url"];
			isGateway = obj["isGateway"];
			nickName = obj["nickName"];
			groups = (obj["groups"] as String).split(",");
			emailAddress = obj["emailAddress"];
			lastSeen = obj["lastSeen"];
			status = Status.OFFLINE;
			broadcast = obj["broadcast"];
		}
		
		public function toDatabaseValues(userId:int=-1):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("url", url),
				new DatabaseValue("isGateway", isGateway),
				new DatabaseValue("nickName", nickName),
				new DatabaseValue("groups", (groups as Array).join(",")),
				new DatabaseValue("emailAddress", emailAddress),
				new DatabaseValue("broadcast", broadcast)];
		}
		
		public static function createFromStanza(stanza:Object):Buddy
		{
			var timeNow:Date = new Date();
			var newBuddy:Buddy = new Buddy();

			newBuddy.jid = stanza['jid'];
//			newBuddy.url 
			newBuddy.isGateway = (newBuddy.jid.search("@") == 0);
			newBuddy.nickName = (stanza['nick'] == "") ? newBuddy.jid : stanza['nick'];
			newBuddy.groups = stanza['groups'];
//			newBuddy.emailAddress
			newBuddy.lastSeen = timeNow;
			newBuddy.status = stanza['type'];
			newBuddy.customStatus = stanza['status'];
//			newBuddy.broadcast

			return newBuddy;
		}
		
		override public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus;
		}
	}
}