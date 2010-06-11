package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.HasAvatarEvent;
	import com.cleartext.ximpp.events.StatusEvent;
	
	import flash.display.BitmapData;
	
	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;

	public class BuddyBase extends HasAvatarBase implements IBuddy
	{
		//----------------------------------------
		//  CONSTRUCTOR
		//----------------------------------------
		
		public function BuddyBase(jid:String)
		{
			super(jid);

			status.addEventListener(StatusEvent.STATUS_CHANGED,
				function():void
				{
					dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
				});
		}

		//--------------------------------------------------
		//
		//  I SPROUT LIST DATA
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  UID
		//----------------------------------------
		
		private var _uid:String;
		public function get uid():String
		{
			if(!_uid)
				_uid = UIDUtil.createUID();
			return _uid;
		}
		
		//----------------------------------------
		//  DISPOSE()
		//----------------------------------------
		
		public function dispose():void
		{
		}

		//--------------------------------------------------
		//
		//  PROPERTIES STORED IN DATABASE
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  AVATAR
		//----------------------------------------
		
		// overriden because we use the tempAvatarHash value
		// when a buddy's avatar hash changes, we store the new 
		// value of avatarHash using the tempAvatarHash value and
		// do a vcard request. We only want to set avatarHash to the
		// new value after that request has returned and we are
		// setting the new value of avatar
		override public function set avatar(value:BitmapData):void
		{
			if(avatar != value)
			{
				if(tempAvatarHash)
				{
					avatarHash = tempAvatarHash;
					tempAvatarHash = null;
				}
				
				super.avatar = value;
			}
		}
	
		//----------------------------------------
		//  BUDDY ID
		//----------------------------------------
		
		private var _buddyId:int = -1;
		public function get buddyId():int
		{
			return _buddyId;
		}
		public function set buddyId(value:int):void
		{
			if(buddyId == -1)
				_buddyId = value;
			else if(this != Buddy.ALL_MICRO_BLOGGING_BUDDY)
				throw new Error();
		}
		
		//----------------------------------------
		//  CUSTOM STATUS
		//----------------------------------------
		
		private var _customStatus:String;
		[Bindable (event="changeSave")]
		public function get customStatus():String
		{
			return _customStatus;
		}
		public function set customStatus(value:String):void
		{
			if(customStatus != value)
			{
				_customStatus = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		//----------------------------------------
		//  LAST SEEN
		//----------------------------------------
		
		private var _lastSeen:int;
		[Bindable (event="changeSave")]
		public function get lastSeen():int
		{
			return _lastSeen;
		}
		public function set lastSeen(value:int):void
		{
			if(lastSeen != value)
			{
				_lastSeen = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}

		//----------------------------------------
		//  AUTO OPEN TAB
		//----------------------------------------
		
		// when we receive a new message from this buddy should we
		// automatically open a new tab
		private var _autoOpenTab:Boolean = true;
		[Bindable("changeSave")]
		public function get autoOpenTab():Boolean
		{
			return _autoOpenTab;
		}
		public function set autoOpenTab(value:Boolean):void
		{
			if(autoOpenTab != value)
			{
				_autoOpenTab = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}

		//----------------------------------------
		//  OPEN TAB
		//----------------------------------------
		
		// is a chat tab currently open, this is used to restore open
		// chats on restart
		private var _openTab:Boolean = false;
		[Bindable("changeSave")]
		public function get openTab():Boolean
		{
			return _openTab;
		}
		public function set openTab(value:Boolean):void
		{
			if(openTab != value)
			{
				_openTab = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}

		//----------------------------------------
		//  UNREAD MESSAGE COUNT
		//----------------------------------------
		
		private var _unreadMessages:int = 0;
		[Bindable(event="changeSave")]
		public function get unreadMessages():int
		{
			return _unreadMessages;
		}
		public function set unreadMessages(value:int):void
		{
			if(_unreadMessages != value)
			{
				_unreadMessages = value;
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
		public function get isPerson():Boolean
		{
			return false;
		}
		
		//----------------------------------------
		//  IS GATEWAY
		//----------------------------------------
		
		[Bindable (event="changeSave")]
		public function get isGateway():Boolean
		{
			return false;
		}
		
		//----------------------------------------
		//  IS MICRO BLOGGING
		//----------------------------------------
		
		[Bindable (event="changeSave")]
		public function get isMicroBlogging():Boolean
		{
			return false;
		}
		public function set isMicroBlogging(value:Boolean):void
		{
		}
		
		//----------------------------------------
		//  IS TYPING
		//----------------------------------------
		
		[Bindable (event="isTypingChange")]
		public function get isTyping():Boolean
		{
			return false;
		}
		public function set isTyping(value:Boolean):void
		{
		}

		//----------------------------------------
		//  TEMP AVATAR HASH
		//----------------------------------------
		
		private var _tempAvatarHash:String;
		public function get tempAvatarHash():String
		{
			return _tempAvatarHash;
		}
		public function set tempAvatarHash(value:String):void
		{
			_tempAvatarHash = value;
		}

		//----------------------------------------
		//  STATUS
		//----------------------------------------
		
		protected var _status:Status = new Status(Status.OFFLINE);
		[Bindable("changeSave")]
		public function get status():Status
		{
			return _status;
		}
			
		//----------------------------------------
		//  PARTICIPANTS
		//----------------------------------------
		
		public function get participants():ArrayCollection
		{
			return null;
		}
			
		//--------------------------------------------------
		//
		//  DISCOVERY ETC - TODO
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  FEATURES
		//----------------------------------------
		
		private var _features:Array = new Array();
		public function get features():Array
		{
			return _features;
		}

		//----------------------------------------
		//  IDENTITIES
		//----------------------------------------
		
		private var _identities:Array = new Array();
		public function get identities():Array
		{
			return _identities;
		}

		//----------------------------------------
		//  ITEMS
		//----------------------------------------
		
		private var _items:Array = new Array();
		public function get items():Array
		{
			return _items;
		}
		
		//--------------------------------------------------
		//
		//  SHORTCUTS
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  HOST
		//----------------------------------------
		
		public function get host():String
		{
			var index:int = jid.indexOf("@");
			if(index != -1)
				return jid.substr(index+1);
			else 
				return jid;
		}
		
		//----------------------------------------
		//  USERNAME
		//----------------------------------------
		
		public function get username():String
		{
			var index:int = jid.indexOf("@");
			if(index != -1)
				return jid.substr(0, index);
			else 
				return jid;
		}
		
		//----------------------------------------
		//  FULL JID
		//----------------------------------------
		
		public function get fullJid():String
		{
			return jid;
		}
		
		//----------------------------------------
		//  ADD EVENT LISTENER
		//----------------------------------------
		
		// override this so we can set useWeakReference to true
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = true):void
		{
			super.addEventListener(type, listener, useCapture, priority);
		}
		
		//----------------------------------------
		//  CREATE DATABASE VALUES
		//----------------------------------------
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", getNickname()),
				new DatabaseValue("lastSeen", lastSeen),
				new DatabaseValue("avatar", avatarString),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("openTab", openTab),
				new DatabaseValue("autoOpenTab", autoOpenTab),
				new DatabaseValue("unreadMessages", unreadMessages),
				];
		}
	}
}