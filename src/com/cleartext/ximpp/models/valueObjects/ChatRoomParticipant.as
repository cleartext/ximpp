package com.cleartext.ximpp.models.valueObjects
{
	public class ChatRoomParticipant
	{
		public var nickname:String;
		public var jid:String;
		public var affiliation:String;
		public var role:String;
		
		private var _status:Status = new Status();
		public function get status():Status
		{
			return _status;
		}
		
		public function toString():String
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