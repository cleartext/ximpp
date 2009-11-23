package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.XimppUtils;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.BitmapData;;
		
	[Bindable]
	public class Buddy extends SproutListDataBase implements IXimppValueObject
	{
		public function Buddy()
		{
			super();
		}
		
		public static const CREATE_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddies (" +
			"buddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"jid TEXT UNIQUE, " +
			"nickName TEXT, " +
			"groups TEXT, " +
			"lastSeen DATE, " + 
			"avatar TEXT, " +
			"service BOOLEAN);";

		// storred in database		
		public var buddyId:int = -1;
		public var jid:String;
		public var nickName:String;
		public var groups:Array = new Array();
		public var service:Boolean = false;
		public var lastSeen:Date;
		public var avatar:BitmapData;

		// not storred in database 
		public var used:Boolean = true;
		public var resource:String = "";
		public var status:String = Status.OFFLINE;
		public var customStatus:String;
		
		public function fill(obj:Object):void
		{
			buddyId = obj["buddyId"];
			jid = obj["jid"];
			nickName = obj["nickName"];
//			groups = (obj["groups"] as String).split(",");
			service = obj["service"];
			lastSeen = new Date(obj["lastSeen"]);
			avatar = XimppUtils.stringToAvatar(obj["avatar"]);
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickName", nickName),
				new DatabaseValue("groups", groups.join(",")),
				new DatabaseValue("service", service),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar))];
		}
		
		public static function createFromStanza(stanza:Object):Buddy
		{
			var newBuddy:Buddy = new Buddy();

			newBuddy.jid = stanza['jid'];
			newBuddy.nickName = (stanza['nick'] == "") ? newBuddy.jid : stanza['nick'];
			newBuddy.groups = stanza['groups'];
			newBuddy.lastSeen = new Date();
			newBuddy.status = stanza['type'];
			newBuddy.customStatus = stanza['status'];

			return newBuddy;
		}
		
		public function get fullJid():String
		{
			return jid + "/" + resource;
		}
		
		override public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus;
		}
		
		public function toXML():XML
		{
			return null;
		}
	}
}