package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.StatusEvent;
	import com.cleartext.ximpp.models.AvatarUtils;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.BitmapData;;

	[Event(name="changed", type="com.cleartext.ximpp.events.BuddyEvent")]		

	[Bindable]
	public class Buddy extends SproutListDataBase implements IXimppValueObject
	{
		
		/** TODO: subscription property */
		
		public function Buddy(jid:String)
		{
			super();
			setJid(jid);
			status.addEventListener(StatusEvent.STATUS_CHANGED,
				function():void
				{
					dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
				});
		}
		
		public static const CREATE_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddies (" +
			"buddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"jid TEXT UNIQUE, " +
			"nickName TEXT, " +
			"groups TEXT, " +
			"lastSeen DATE, " + 
			"subscription TEXT," +
			"avatar TEXT, " + 
			"avatarHash TEXT, " + 
			"customStatus TEXT);";
			
		// storred in database		
		private var _buddyId:int = -1;
		public function get buddyId():int
		{
			return _buddyId;
		}
		public function setBuddyId(value:int):void
		{
			if(_buddyId == -1)
				_buddyId = value;
			else
				throw new Error();
		}
		
		private var _jid:String;
		public function get jid():String
		{
			return _jid;
		}
		public function setJid(value:String):void
		{
			_jid = value;
		}
		
		private var _nickName:String;
		public function get nickName():String
		{
			return (_nickName) ? _nickName : jid;
		}
		public function setNickName(value:String):void
		{
			if(_nickName != value)
			{
				_nickName = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		private var _lastSeen:Date;
		public function get lastSeen():Date
		{
			return _lastSeen;
		}
		public function setLastSeen(value:Date):void
		{
			if(_lastSeen != value)
			{
				_lastSeen = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		private var _customStatus:String;
		[Bindable (event="buddyChanged")]
		public function get customStatus():String
		{
			return _customStatus;
		}
		public function setCustomStatus(value:String):void
		{
			if(_customStatus != value)
			{
				_customStatus = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		private var _avatar:BitmapData;
		[Bindable (event="buddyChanged")]
		public function get avatar():BitmapData
		{
			return _avatar;
		}
		public function setAvatar(value:BitmapData):void
		{
			if(_avatar != value)
			{
				if(tempAvatarHash)
				{
					avatarHash = tempAvatarHash;
					tempAvatarHash = null;
				}
				
				_avatar = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		public var avatarHash:String;
		public var groups:Array = new Array();
		public var subscription:String = SubscriptionTypes.NONE;
		
		// not storred in database 
		public var used:Boolean = true;
		public var resource:String;
		public var tempAvatarHash:String;

		private var _status:Status = new Status(Status.OFFLINE);
		public function get status():Status
		{
			return _status;
		}
				
		public static function createFromDB(obj:Object):IXimppValueObject
		{
			var jid:String = obj["jid"];
			var newBuddy:Buddy = new Buddy(jid);
			
			newBuddy.setBuddyId(obj["buddyId"]);
			newBuddy.setNickName(obj["nickName"]);
			newBuddy.setLastSeen(obj["lastSeen"]);
			newBuddy.setCustomStatus(obj["customStatus"]);

			newBuddy.groups = (obj["groups"] as String).split(",");
			newBuddy.avatarHash = obj["avatarHash"];
			newBuddy.subscription = obj["subscription"];
			AvatarUtils.stringToAvatar(obj["avatar"], newBuddy);

			return newBuddy;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickName", _nickName),
				new DatabaseValue("groups", groups.join(",")),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("subscription", subscription),
				new DatabaseValue("avatar", AvatarUtils.avatarToString(avatar)),
				new DatabaseValue("customStatus", customStatus),
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