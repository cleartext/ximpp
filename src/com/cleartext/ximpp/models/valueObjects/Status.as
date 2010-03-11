package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.StatusEvent;
	
	import flash.events.EventDispatcher;
	
	[Event(name="statusChanged", type="com.cleartext.ximpp.events.StatusEvent")]

	public class Status extends EventDispatcher
	{
		// unavailable
		public static const OFFLINE:String = "offline";
		public static const UNSUBSCRIBED:String = "unsubscribed";
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
			// when setting a buddy's status to OFFLINE, we don't want
			// to overwrite the UNSUBSCIRBED value
			if(value == OFFLINE && this.value == UNSUBSCRIBED)
				return;
			
			if(_value != value)
			{
				_value = value;
				dispatchEvent(new StatusEvent(StatusEvent.STATUS_CHANGED));
			}
		}

		private var _edit:Boolean = false;
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

		private var _numUnread:int = 0;
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
		public function setFromStanzaType(type:String):Boolean
		{
			switch(type)
			{
				case "unavailable": 	value = OFFLINE; break;
				case "subscribed":		value = OFFLINE; break;
				case "unsubscribed": 	value = UNSUBSCRIBED; break;
				case "":				value = AVAILABLE; break;
				case "available":		value = AVAILABLE; break;
				case "chat":			value = AVAILABLE; break;
				case "away":			value = AWAY; break;
				case "dnd":				value = BUSY; break;
				case "inactive" :		value = EXTENDED_AWAY; break;
				case "xa":				value = EXTENDED_AWAY; break;
				case "error":			value = ERROR; return true;
				default:				value = UNKNOWN + ": " + type;
			}
			return false;
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
		
		public function sortNumber():int
		{
			switch(value)
			{
				case AVAILABLE :
					return 0;
				case AWAY :
					return 1;
				case BUSY :
					return 2;
				case EXTENDED_AWAY :
					return 3;
				case ERROR :
					return 4;
				case UNSUBSCRIBED :
					return 5;
				case UNKNOWN :
					return 6;
				default :
					return 7;
			}
		}
		
		public function isOffline():Boolean
		{
			return sortNumber() > 5;
		}
	}
}