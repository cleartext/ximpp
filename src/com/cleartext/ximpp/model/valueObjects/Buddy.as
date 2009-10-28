package com.cleartext.ximpp.model.valueObjects
{
	import com.cleartext.ximpp.database.DatabaseValue;
	import com.cleartext.ximpp.model.XModel;;
	
	public class Buddy
	{
		public static const CREATE_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddies (" +
			"buddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"timeStamp DATE, " +
			"jid TEXT UNIQUE, " +
			"resource TEXT," + 
			"url TEXT, " +
			"isGateway BOOLEAN, " +
			"firstName TEXT, " +
			"lastName TEXT, " +
			"nickName TEXT, " +
			"groups TEXT, " +
			"emailAddress TEXT, " +
			"userEnabled BOOLEAN, " +
			"lastSeen DATE, " +
			"status TEXT, " +
			"customStatus TEXT, " +
			"avatar TEXT, " +
			"broadcast BOOLEAN);";
		
		public var buddyId:int = -1;
		public var timeStamp:Date;
		public var jid:String = "";
		public var resource:String = "";
		public var url:String = "";
		public var isGateway:Boolean = false;
		public var firstName:String = "";
		public var lastName:String = "";
		[Bindable]
		public var nickName:String = "";
		[Bindable]
		public var groups:Array;
		public var emailAddress:String = "";
		public var userEnabled:Boolean = true;
		[Bindable]
		public var lastSeen:Date;
		[Bindable]
		public var status:String = "";
		[Bindable]
		public var customStatus:String = "";
		public var broadcast:Boolean = false;
		
		public function fill(obj:Object):void
		{
			buddyId = obj["buddyId"];
			timeStamp = obj["timeStamp"];
			jid = obj["jid"];
			resource = obj["resource"];
			url = obj["url"];
			isGateway = obj["isGateway"];
			firstName = obj["firstName"];
			lastName = obj["lastName"];
			nickName = obj["nickName"];
			groups = String(obj["groupName"]).split(",");
			emailAddress = obj["emailAddress"];
			userEnabled = obj["userEnabled"];
			lastSeen = obj["lastSeen"];
			status = obj["status"];
			customStatus = obj["customStatus"];
			broadcast = obj["broadcast"];
		}
		
		public function get databaseValues():Array
		{
			return [new DatabaseValue("userId", XModel.getInstance().userId),
				new DatabaseValue("timeStamp", timeStamp),
				new DatabaseValue("jid", jid),
				new DatabaseValue("resource", resource),
				new DatabaseValue("url", url),
				new DatabaseValue("isGateway", isGateway),
				new DatabaseValue("firstName", firstName),
				new DatabaseValue("lastName", lastName),
				new DatabaseValue("nickName", nickName),
				new DatabaseValue("groups", groups.join(",")),
				new DatabaseValue("emailAddress", emailAddress),
				new DatabaseValue("userEnabled", userEnabled),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("status", status),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("broadcast", broadcast)];
		}
		
		public static function createFromStanza(stanza:Object):Buddy
		{
			var timeNow:Date = new Date();
			var newBuddy:Buddy = new Buddy();

			newBuddy.timeStamp = timeNow;
			newBuddy.jid = stanza['jid'];
//			newBuddy.resource
//			newBuddy.url 
			newBuddy.isGateway = (newBuddy.jid.search("@") == 0);
//			newBuddy.firstName
//			newBuddy.lastName
			newBuddy.nickName = (stanza['nick'] == "") ? newBuddy.jid : stanza['nick'];
			newBuddy.groups = stanza['groups'];
//			newBuddy.emailAddress
//			newBuddy.userEnabled
			newBuddy.lastSeen = timeNow;
			newBuddy.status = stanza['type'];
			newBuddy.customStatus = stanza['status'];
//			newBuddy.broadcast

			return newBuddy;
		}
		
		public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus;
		}
	}
}