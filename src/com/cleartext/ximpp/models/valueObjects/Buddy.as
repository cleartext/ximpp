package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.XimppUtils;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;;

	[Event(name="avatarChanged", type="com.cleartext.ximpp.events.BuddyEvent")]		

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
			"service BOOLEAN, " + 
			"avatar TEXT, " + 
			"avatarHash TEXT);";

		// storred in database		
		public var buddyId:int = -1;
		public var jid:String;
		public var nickName:String;
		public var groups:Array = new Array();
		public var service:Boolean = false;
		public var lastSeen:Date;

		private var _avatar:BitmapData;
		[Bindable (event="avatarChanged")]
		public function get avatar():BitmapData
		{
			return _avatar;
		}
		public function set avatar(value:BitmapData):void
		{
			if(_avatar != value)
			{
				_avatar = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.AVATAR_CHANGED));
			}
		}
		public var avatarHash:String;

		// not storred in database 
		public var used:Boolean = true;
		public var resource:String = "";
		public var tempAvatarHash:String;
		private var _status:Status = new Status(Status.OFFLINE);
		public function get status():Status
		{
			return _status;
		}
		public var customStatus:String;
		
		public function fill(obj:Object):void
		{
			buddyId = obj["buddyId"];
			jid = obj["jid"];
			nickName = obj["nickName"];
//			groups = (obj["groups"] as String).split(",");
			service = obj["service"];
			lastSeen = new Date(obj["lastSeen"]);
			if(obj["avatar"])
			{
				if(obj["avatar"] is String)
					XimppUtils.stringToAvatar(obj["avatar"],
						function(event:Event):void
						{
							var bmd:BitmapData = Bitmap(event.target.content).bitmapData;
							if(bmd)
								avatar = bmd;
						});
				else if(obj["avatar"] is BitmapData)
					avatar = obj["avatar"];
			}
			if(obj["avatarHash"])
				avatarHash = obj["avatarHash"];
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
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar)),
				new DatabaseValue("avatarHash", avatarHash)];
		}
		
		public static function createFromStanza(stanza:Object):Buddy
		{
			var newBuddy:Buddy = new Buddy();

			newBuddy.jid = stanza['jid'];
			newBuddy.nickName = (stanza['nick'] == "") ? newBuddy.jid : stanza['nick'];
			newBuddy.groups = stanza['groups'];
			newBuddy.lastSeen = new Date();
			newBuddy.status.value = stanza['type'];
			newBuddy.customStatus = stanza['status'];

			return newBuddy;
		}
		
		public function get fullJid():String
		{
			return jid + "/" + resource;
		}
		
		override public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus + " avatarHash:" + avatarHash;
		}
		
		public function toXML():XML
		{
			return null;
		}
	}
}