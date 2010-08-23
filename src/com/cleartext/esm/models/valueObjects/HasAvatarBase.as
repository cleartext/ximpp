package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.HasAvatarEvent;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;

	public class HasAvatarBase extends EventDispatcher implements IHasAvatar
	{
		//----------------------------------------
		//  CONSTRUCTOR
		//----------------------------------------
		
		public function HasAvatarBase(jid:String)
		{
			super();
			_jid = jid;
		}
		
		//--------------------------------------------------
		//
		//  PROPERTIES STORED IN DATABASE
		//
		//--------------------------------------------------
		
		//----------------------------------------
		//  JID
		//----------------------------------------
		
		private var _jid:String;
		public function get jid():String
		{
			return _jid;
		}
		public function set jid(value:String):void
		{
			_jid = value;
		}
		
		//----------------------------------------
		//  NICKNAME
		//----------------------------------------
		
		private var _nickname:String;
		[Bindable (event="changeSave")]
		public function get nickname():String
		{
			return (_nickname) ? _nickname : jid;
		}
		public function set nickname(value:String):void
		{
			if(nickname != value)
			{
				_nickname = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		// get the actual value of _nickname
		public function getNickname():String
		{
			return _nickname;
		}
		
//		//----------------------------------------
//		//  AVATAR
//		//----------------------------------------
//		
//		private var _avatar:BitmapData;
//		[Bindable (event="avatarChange")]
//		public function get avatar():BitmapData
//		{
//			return _avatar;
//		}
//		public function set avatar(value:BitmapData):void
//		{
//			if(avatar != value)
//			{
//				_avatar = value;
//				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.AVATAR_CHANGE));
//			}
//		}
//
//		//----------------------------------------
//		//  AVATAR STRING
//		//----------------------------------------
//		
//		private var _avatarString:String;
//		[Bindable (event="changeSave")]
//		public function get avatarString():String
//		{
//			return _avatarString;
//		}
//		public function set avatarString(value:String):void
//		{
//			if(avatarString != value)
//			{
//				_avatarString = value;
//				AvatarUtils.stringToAvatar(avatarString, this, "avatar");
//				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
//			}
//		}
//		
//		//----------------------------------------
//		//  SET AVATAR STRING 
//		//----------------------------------------
//		
//		// used to just set _avatarString without re-calculating
//		// the avatar and dispatching an event
//		public function setAvatarString(value:String):void
//		{
//			_avatarString = value;
//		}
//
//		//----------------------------------------
//		//  AVATAR HASH
//		//----------------------------------------
//		
//		private var _avatarHash:String;
//		[Bindable (event="changeSave")]
//		public function get avatarHash():String
//		{
//			return _avatarHash;
//		}
//		public function set avatarHash(value:String):void
//		{
//			if(avatarHash != value)
//			{
//				_avatarHash = value;
//				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
//			}
//		}
	}
}