package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.StatusEvent;
	import com.cleartext.ximpp.models.AvatarUtils;
	import com.cleartext.ximpp.models.types.MicroBloggingTypes;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.BitmapData;
	import flash.events.Event;;

	[Event(name="changed", type="com.cleartext.ximpp.events.BuddyEvent")]		

	[Bindable]
	public class Buddy extends SproutListDataBase implements IXimppValueObject
	{
		public static const ALL_MICRO_BLOGGING_JID:String = "Micro Blogging";
		public static const ALL_MICRO_BLOGGING_BUDDY:Buddy = new Buddy(ALL_MICRO_BLOGGING_JID);

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
			_isGateway = _jid && _jid.indexOf("@") == -1;
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

		[Bindable (event="buddyChanged")]
		public function get microBlogging():Boolean
		{
			return (jid == ALL_MICRO_BLOGGING_JID || groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP) != -1);
		}
		public function set microBlogging(value:Boolean):void
		{
			if(microBlogging != value)
			{
				// find if we already have the correct group
				var index:int = groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
				
				// add or remove the group value as required
				if(index!=-1 && !value)
					groups.splice(index,1);
				else if(index==-1 && value)
					groups.push(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
				
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		private var _subscription:String = SubscriptionTypes.NONE;
		[Bindable(event="buddyChanged")]
		public function get subscription():String
		{
			return _subscription;
		}
		public function set subscription(value:String):void
		{
			_subscription = value;
			if(!subscribedTo)
				status.value = Status.UNSUBSCRIBED;
			
			dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
		}
			
		public var avatarHash:String;
		public var groups:Array = new Array();
		
		//------------------------------------
		// not storred in database 
		//------------------------------------

		private var _unreadMessageCount:int = 0;
		[Bindable(event="buddyChanged")]
		public function get unreadMessageCount():int
		{
			return _unreadMessageCount;
		}
		public function set unreadMessageCount(value:int):void
		{
			if(_unreadMessageCount != value)
			{
				_unreadMessageCount = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		// are we subscribed to this buddies status updates?
		public function get subscribedTo():Boolean
		{
			return (subscription==SubscriptionTypes.TO || subscription==SubscriptionTypes.BOTH); 
		}
		
		// are we publishing our status updates to this buddy?
		public function get publishTo():Boolean
		{
			return (subscription==SubscriptionTypes.FROM || subscription==SubscriptionTypes.BOTH); 
		}
		
		// the current resource this buddy is using
		public var resource:String;
		// store the new avatarHash whilst we are downloading the 
		// new hash until we have got the new avatar, we don't 
		// want to set the avatarHash
		public var tempAvatarHash:String;
		// don't store this in the database as it is easier to set
		// in the set jid(value:String) method
		private var _isGateway:Boolean = false;
		public function get isGateway():Boolean
		{
			return _isGateway;
		}
		// flag used by the roster handler in xmppModel to refresh the
		// buddy list
		public var used:Boolean = false;

		private var _status:Status = new Status(Status.OFFLINE);
		[Bindable("buddyChanged")]
		public function get status():Status
		{
			if(jid == ALL_MICRO_BLOGGING_JID)
				_status.value = Status.AVAILABLE;
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