package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.ChatRoomEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;

	public class ChatRoomModel extends EventDispatcher
	{
		private var _chatRooms:ArrayCollection;
		public function get chatRooms():ArrayCollection
		{
			return _chatRooms;
		}
		
		public function ChatRoomModel(target:IEventDispatcher=null)
		{
			super(target);
			_chatRooms = new ArrayCollection();
		}
		
		public function join(roomJid:String, nickname:String, password:String):void
		{
			// send presence and register for presence messages from this roomJid
		}
		
		public function presenceHandler(event:ChatRoomEvent):void
		{
			
		}
		
		public function messageHandler(event:ChatRoomEvent):void
		{
			
		}
		
		public function errorHandler(event:ChatRoomEvent):void
		{
			
		}
		
		public function iqHandler(event:ChatRoomEvent):void
		{
			
		}
		
	}
}