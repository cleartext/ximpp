package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyRequestEvent;
	import com.universalsprout.flex.components.list.SproutListDataBase;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	public class BuddyRequest extends SproutListDataBase implements IEventDispatcher
	{
		public function BuddyRequest()
		{
			super();
			dispatcher = new EventDispatcher(this);
		}
		
		private var dispatcher:EventDispatcher;
		
		public static const CREATE_BUDDY_REQUESTS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS buddyRequests (" +
			"buddyRequestId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"userId INTEGER, " +
			"jid TEXT, " +
			"nickname TEXT, " +
			"incomming BOOLEAN, " +
			"timestamp DATE, " + 
			"message TEXT);";
			
		// storred in database		
		public var buddyRequestId:int = -1;
		public var jid:String;
		public var incomming:Boolean;
		
		private var _timestamp:Date;
		[Bindable (event="buddyRequestChanged")]
		public function get timestamp():Date
		{
			return _timestamp;
		}
		public function set timestamp(value:Date):void
		{
			if(timestamp != value)
			{
				_timestamp = value;
				dispatchEvent(new BuddyRequestEvent(BuddyRequestEvent.BUDDY_REQUEST_CHANGED));
			}
		}

		private var _nickname:String;
		[Bindable (event="buddyRequestChanged")]
		public function get nickname():String
		{
			return _nickname;
		}
		public function set nickname(value:String):void
		{
			if(nickname != value)
			{
				_nickname = value;
				dispatchEvent(new BuddyRequestEvent(BuddyRequestEvent.BUDDY_REQUEST_CHANGED));
			}
		}
			
		private var _message:String;
		[Bindable (event="buddyRequestChanged")]
		public function get message():String
		{
			return _message;
		}
		public function set message(value:String):void
		{
			if(message != value)
			{
				_message = value;
				dispatchEvent(new BuddyRequestEvent(BuddyRequestEvent.BUDDY_REQUEST_CHANGED));
			}
		}
			
		public static function createFromDB(obj:Object):BuddyRequest
		{
			var newRequest:BuddyRequest = new BuddyRequest();
			newRequest.buddyRequestId = obj["buddyRequestId"];
			newRequest.jid = obj["jid"];
			newRequest.nickname = obj["nickname"];
			newRequest.incomming = obj["incomming"];
			newRequest.timestamp = obj["timestamp"];
			newRequest.message = obj["message"];
			return newRequest;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", nickname),
				new DatabaseValue("incomming", incomming),
				new DatabaseValue("timestamp", timestamp),
				new DatabaseValue("message", message)];
		}
		
		public function toString():String
		{
			return "jid:" + jid + " incomming:" + incomming + " nickname: " + nickname + " timestamp:" + timestamp + " message:" + message;
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