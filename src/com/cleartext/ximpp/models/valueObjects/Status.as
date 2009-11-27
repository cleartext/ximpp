package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.StatusEvent;
	
	import flash.events.EventDispatcher;
	
	[Event(name="statusChanged", type="com.cleartext.ximpp.events.StatusEvent")]

	public class Status extends EventDispatcher
	{
		// unavailable
		public static const OFFLINE:String = "offline";
		// available
		public static const AVAILABLE:String = "available";
		public static const AWAY:String = "away";
		public static const BUSY:String = "busy";
		public static const EXTENDED_AWAY:String = "inactive";
		public static const UNKNOWN:String = "unknown";
		
		// status's the user can choose from
		public static const USER_TYPES:Array = [OFFLINE, AVAILABLE, BUSY, AWAY];
		
		// other status'
		public static const CONNECTING:String = "connecting...";
		public static const ERROR:String = "error";
		public static const CLOSE:String = "close";
		
		public function Status(value:String=UNKNOWN)
		{
			this.value = value;
			edit = false;
			numUnread = 0;
		}
		
		private var _value:String;
		[Bindable (event="statusChanged")]
		public function get value():String
		{
			return _value;	
		}
		public function set value(value:String):void
		{
			if(_value != value)
			{
				_value = value;
				dispatchEvent(new StatusEvent(StatusEvent.STATUS_CHANGED));
			}
		}

		private var _edit:Boolean;
		[Bindable (event="statusChanged")]
		public function get edit():Boolean
		{
			return _edit;	
		}
		public function set edit(value:Boolean):void
		{
			if(_edit != value)
			{
				_edit = value;
				dispatchEvent(new StatusEvent(StatusEvent.STATUS_CHANGED));
			}
		}

		private var _numUnread:int;
		[Bindable (event="statusChanged")]
		public function get numUnread():int
		{
			return _numUnread;	
		}
		public function set numUnread(value:int):void
		{
			if(_numUnread != value)
			{
				_numUnread = value;
				dispatchEvent(new StatusEvent(StatusEvent.STATUS_CHANGED));
			}
		}
		
		// find a status value from what the xmpp libray tells us
		public function setFromShow(show:String):void
		{
			switch(show)
			{
				case "unavailable" : value = OFFLINE; break;
				case "" : value = AVAILABLE; break;
				case "available" : value = AVAILABLE; break;
				case "chat" : value = AVAILABLE; break;
				case "away" : value = AWAY; break;
				case "dnd" : value = BUSY; break;
				case "xa" : value = EXTENDED_AWAY; break;
				default : value = UNKNOWN;
			}
		}
		
		// generate something the xmpp library will understand
		public function toShow():String
		{
			switch(value)
			{
				case OFFLINE : return "unavailable";
				case AVAILABLE : return "chat";
				case AWAY : return "away";
				case BUSY : return "dnd";
				case EXTENDED_AWAY : return "xa";
				default : return "";
			}
		}
	}
}