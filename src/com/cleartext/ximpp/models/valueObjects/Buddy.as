package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.StatusEvent;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.types.MicroBloggingTypes;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.utils.AvatarUtils;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.display.BitmapData;;

	[Event(name="changed", type="com.cleartext.ximpp.events.BuddyEvent")]		

	[Bindable]
	public class Buddy extends SproutListDataBase implements IBuddy
	{
		public static const ALL_MICRO_BLOGGING_JID:String = "All Social";
		public static const ALL_MICRO_BLOGGING_BUDDY:Buddy = new Buddy(ALL_MICRO_BLOGGING_JID);

		private var dispatcher:EventDispatcher;

		public function Buddy(jid:String)
		{
			dispatcher = new EventDispatcher(this);
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
			"sendTo BOOLEAN, " + 
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
			else if(this != ALL_MICRO_BLOGGING_BUDDY)
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
			else if(status.value == Status.UNSUBSCRIBED)
			{
				// hack cause we can't set an unsubscribed
				// status to offline
				status.value = Status.UNKNOWN;
				status.value = Status.OFFLINE;
			}
			
			dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
		}
			
		// flag used by the roster handler in xmppModel to refresh the
		// buddy list
		private var _sendTo:Boolean = true;
		[Bindable("buddyChanged")]
		public function get sendTo():Boolean
		{
			return _sendTo;
		}
		public function set sendTo(value:Boolean):void
		{
			if(_sendTo != value)
			{
				_sendTo = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
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

		private var _status:Status = new Status(Status.OFFLINE);
		[Bindable("buddyChanged")]
		public function get status():Status
		{
			if(jid == ALL_MICRO_BLOGGING_JID)
				_status.value = Status.AVAILABLE;
			return _status;
		}
			
		public static function createFromDB(obj:Object):Buddy
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
			newBuddy.sendTo = obj["sendTo"];
			newBuddy.microBlogging = (groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP) != -1);
			newBuddy.avatarHash = obj["avatarHash"];
			newBuddy.subscription = obj["subscription"];
			AvatarUtils.stringToAvatar(obj["avatar"], newBuddy, "avatar");

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
				new DatabaseValue("sendTo", sendTo),
				new DatabaseValue("avatarHash", avatarHash)];
		}
		
		public function get fullJid():String
		{
			return jid + ((resource) ? "/" + resource : "");
		}
		
		public function toString():String
		{
			return "jid:" + jid + " nickName:" + nickName + " lastSeen:" + lastSeen + " status:" + status + " customStatus:" + customStatus + " avatarHash:" + avatarHash;
		}
		   
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = true):void
		{
			dispatcher.addEventListener(type, listener, useCapture, priority);
		}
		   
		public function dispatchEvent(event:Event):Boolean
		{
			return dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return dispatcher.hasEventListener(type);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		   
		public function willTrigger(type:String):Boolean
		{
			return dispatcher.willTrigger(type);
		}
	}
}