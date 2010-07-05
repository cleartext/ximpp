package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.HasAvatarEvent;
	
	import flash.events.EventDispatcher;
	
	public class ChatRoomParticipant extends EventDispatcher implements IHasStatus, IHasJid
	{
		private var _nickname:String;
		[Bindable(event="changeSave")]
		public function get nickname():String
		{
			return _nickname;
		}
		public function set nickname(value:String):void
		{
			if(_nickname != value)
			{
				_nickname = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		private var _jid:String;
		[Bindable(event="changeSave")]
		public function get jid():String
		{
			return _jid;
		}
		public function set jid(value:String):void
		{
			if(_jid != value)
			{
				_jid = value;
				dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
			}
		}
		
		private var _status:Status = new Status();
		public function get status():Status
		{
			return _status;
		}
		public function setStatus(value:String):void
		{
			_status.setFromStanzaType(value);
			dispatchEvent(new HasAvatarEvent(HasAvatarEvent.CHANGE_SAVE));
		}
		
		//----------------------------------------
		//  STATUS SORT INDEX
		//----------------------------------------
		
		public function get statusSortIndex():int
		{
			return status.sortNumber();
		}
		
		public var affiliation:String;
		public var role:String;
		
		override public function toString():String
		{
			if(nickname && jid)
				return nickname + "(" + jid + ")";
			else if(jid)
				return jid;
			else if(nickname)
				return nickname;
			return "";
		}
	}
}