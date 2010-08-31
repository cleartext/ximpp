package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.HasAvatarEvent;
	import com.cleartext.esm.models.AvatarModel;
	import com.cleartext.esm.models.types.MicroBloggingTypes;
	import com.cleartext.esm.models.types.SubscriptionTypes;

	[Bindable]
	public class Buddy extends BuddyBase
	{
		//----------------------------------------
		//  MICRO BLOGGING CONSTANTS
		//----------------------------------------
		
		public static const ALL_MICRO_BLOGGING_JID:String = "My Workstream";
		public static const ALL_MICRO_BLOGGING_BUDDY:Buddy = new Buddy(ALL_MICRO_BLOGGING_JID);

		//----------------------------------------
		//  DATABASE
		//----------------------------------------
		
		public static const CREATE_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddies (" +
			"buddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"jid TEXT UNIQUE, " +
			"nickname TEXT, " +
			"groups TEXT, " +
			"lastSeen DATE, " + 
			"subscription TEXT," +
			"avatar TEXT, " + 
			"avatarHash TEXT, " + 
			"sendTo BOOLEAN, " + 
			"customStatus TEXT);";
		
		public static const TABLE_MODS:Array = [
			{name: "openTab", type: "BOOLEAN"},
			{name: "autoOpenTab", type: "BOOLEAN", defaultVal: "TRUE"},
			{name: "unreadMessages", type: "INTEGER"},
			{name: "buddyType", type: "TEXT"},
			{name: "microBloggingServiceType", type: "TEXT"}
		];
		
		//----------------------------------------
		//  CONSTRUCTOR
		//----------------------------------------
		
		public function Buddy(jid:String)
		{
			super(jid);
			_isGateway = jid.indexOf("@") == -1;
			
			if(jid == ALL_MICRO_BLOGGING_JID)
			{
				_status.value = Status.AVAILABLE;
				_status.imutable = true;
			}
		}
		
		//--------------------------------------------------
		//
		//  PROPERTIES STORED IN DATABASE
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  GROUPS
		//----------------------------------------
		
		private var _groups:Array = new Array();
		[Bindable(event="changeSave")]
		public function get groups():Array
		{
			return _groups;
		}
		public function set groups(value:Array):void
		{
			_groups = value;
			_isMicroBlogging = 
				(jid == ALL_MICRO_BLOGGING_JID || 
				groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP) != -1);
		}
		
		//----------------------------------------
		//  SUBSCRIPTION
		//----------------------------------------
		
		private var _subscription:String = SubscriptionTypes.NONE;
		[Bindable(event="changeSave")]
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
			
			dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
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

		//----------------------------------------
		//  SEND TO
		//----------------------------------------
		
		// when broadcasting to a list of buddies (when sending to workstream
		// or broadcasting to a group) should we send 
		private var _sendTo:Boolean = true;
		[Bindable("changeSave")]
		public function get sendTo():Boolean
		{
			return _sendTo;
		}
		public function set sendTo(value:Boolean):void
		{
			if(sendTo != value)
			{
				_sendTo = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}

		//--------------------------------------------------
		//
		//  PROPERTIES NOT STORED IN DATABASE
		//
		//--------------------------------------------------

		//----------------------------------------
		//  IS PERSON
		//----------------------------------------
		
		[Bindable (event="changeSave")]
		override public function get isPerson():Boolean
		{
			return !_isGateway && !_isMicroBlogging;
		}

		//----------------------------------------
		//  IS GATEWAY
		//----------------------------------------
		
		private var _isGateway:Boolean = false;
		[Bindable (event="changeSave")]
		override public function get isGateway():Boolean
		{
			return _isGateway;
		}

		//----------------------------------------
		//  IS MICRO BLOGGING BUDDY
		//----------------------------------------
		
		private var _isMicroBlogging:Boolean = false;
		[Bindable (event="changeSave")]
		override public function get isMicroBlogging():Boolean
		{
			return _isMicroBlogging || this == ALL_MICRO_BLOGGING_BUDDY;
		}
		override public function set isMicroBlogging(value:Boolean):void
		{
			if(isMicroBlogging != value)
			{
				// find if we already have the correct group
				var index:int = groups.indexOf(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
				
				// add or remove the group value as required
				if(index!=-1 && !value)
				{
					groups.splice(index,1);
					_isMicroBlogging = false;
				}
				else if(index==-1 && value)
				{
					groups.push(MicroBloggingTypes.MICRO_BLOGGING_GROUP);
					_isMicroBlogging = true;
				}

				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		//----------------------------------------
		//  RESOURCE
		//----------------------------------------
		
		public var resource:String;
		
		//----------------------------------------
		//  FULL JID
		//----------------------------------------
		
		override public function get fullJid():String
		{
			return jid + "/" + resource;
		}
		
		//--------------------------------------------------
		//
		//  DATABASE METHODS
		//
		//--------------------------------------------------		
		
		//----------------------------------------
		//  CREATE DATABASE VALUES
		//----------------------------------------
		
		override public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", getNickname()),
				new DatabaseValue("groups", groups.join(",")),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("subscription", subscription),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("sendTo", sendTo),
				new DatabaseValue("openTab", openTab),
				new DatabaseValue("autoOpenTab", autoOpenTab),
				new DatabaseValue("unreadMessages", unreadMessages),
				new DatabaseValue("buddyType", "rosterItem"),
				new DatabaseValue("microBloggingServiceType", microBloggingServiceType)
				];
		}
	}
}