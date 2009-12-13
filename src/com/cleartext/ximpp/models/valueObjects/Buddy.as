package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.XimppUtils;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.BitmapData;;

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
		private var _nickName:String;
		public function get nickName():String
		{
			return (_nickName) ? _nickName : jid;
		}
		public function set nickName(value:String):void
		{
			_nickName = value;
		}
		public var groups:Array = new Array();
		public var service:Boolean = false;
		public var lastSeen:Date;
		public var avatarHash:String;

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
				if(tempAvatarHash)
				{
					avatarHash = tempAvatarHash;
					tempAvatarHash = null;
				}
				
				_avatar = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.AVATAR_CHANGED));
			}
		}

		// not storred in database 
		public var used:Boolean = true;
		public var resource:String;
		public var tempAvatarHash:String;
		public var customStatus:String;

		private var _status:Status = new Status(Status.OFFLINE);
		public function get status():Status
		{
			return _status;
		}
				
		public static function createFromDB(obj:Object):IXimppValueObject
		{
			var newBuddy:Buddy = new Buddy();
			
			newBuddy.buddyId = obj["buddyId"];
			newBuddy.jid = obj["jid"];
			newBuddy.nickName = obj["nickName"];
			newBuddy.groups = (obj["groups"] as String).split(",");
			newBuddy.service = obj["service"];
			newBuddy.avatarHash = obj["avatarHash"];

			if(obj["avatar"])
				XimppUtils.stringToAvatar(obj["avatar"], newBuddy);

			return newBuddy;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickName", _nickName),
				new DatabaseValue("groups", groups.join(",")),
				new DatabaseValue("service", service),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar)),
				new DatabaseValue("avatarHash", avatarHash)];
		}
		
		public function get fullJid():String
		{
			return jid + ((resource) ? "/" + resource : "");
		}
		
		override public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus + " avatarHash:" + avatarHash;
		}
	}
}