package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.StatusEvent;
	import com.cleartext.ximpp.models.AvatarUtils;
	import com.cleartext.ximpp.models.types.MicroBloggingTypes;
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
			this.jid = jid;
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
		public function set buddyId(value:int):void
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
		public function set jid(value:String):void
		{
			_jid = value;
			isGateway = _jid && _jid.indexOf("@") == -1;
		}
		
		private var _nickName:String;
		[Bindable (event="buddyChanged")]
		public function get nickName():String
		{
			return (_nickName) ? _nickName : jid;
		}
		public function set nickName(value:String):void
		{
			if(_nickName != value)
			{
				_nickName = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		private var _isTyping:Boolean = false;
		[Bindable (event="buddyChanged")]
		public function get isTyping():Boolean
		{
			return _isTyping;
		}
		public function set isTyping(value:Boolean):void
		{
			if(_isTyping != value)
			{
				_isTyping = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		private var _lastSeen:Date;
		[Bindable (event="buddyChanged")]
		public function get lastSeen():Date
		{
			return _lastSeen;
		}
		public function set lastSeen(value:Date):void
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
		public function set customStatus(value:String):void
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
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		private var _microBlogging:Boolean = false;
		[Bindable (event="buddyChanged")]
		public function get microBlogging():Boolean
		{
			return _microBlogging;
		}
		public function set microBlogging(value:Boolean):void
		{
			if(_microBlogging != value)
			{
				_microBlogging = value;
				
				// find if we already have the correct group
				var index:int = groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
				
				// add or remove the group value as required
				if(index!=-1 && !microBlogging)
					groups.splice(index,1);
				else if(index==-1 && microBlogging)
					groups.push(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
				
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		public var avatarHash:String;
		public var groups:Array = new Array();
		public var subscription:String = SubscriptionTypes.NONE;
		
		//------------------------------------
		// not storred in database 
		//------------------------------------

		// the current resource this buddy is using
		public var resource:String;
		// store the new avatarHash whilst we are downloading the 
		// new hash until we have got the new avatar, we don't 
		// want to set the avatarHash
		public var tempAvatarHash:String;
		// don't store this in the database as it is easier to set
		// in the set jid(value:String) method
		public var isGateway:Boolean = false;
		// flag used by the roster handler in xmppModel to refresh the
		// buddy list
		public var used:Boolean = false;

		private var _status:Status = new Status(Status.OFFLINE);
		public function get status():Status
		{
			return _status;
		}
			
		public static function createFromDB(obj:Object):IXimppValueObject
		{
			var jid:String = obj["jid"];
			var newBuddy:Buddy = new Buddy(jid);
			
			newBuddy.buddyId = obj["buddyId"];
			newBuddy.nickName = obj["nickName"];
			newBuddy.lastSeen = obj["lastSeen"];
			newBuddy.customStatus = obj["customStatus"];

			var groups:Array = (obj["groups"] as String).split(",");
			if(groups.length == 1 && groups[0] == "")
				groups = [];
			newBuddy.groups = groups;
			newBuddy.microBlogging = (groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP) != -1);
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