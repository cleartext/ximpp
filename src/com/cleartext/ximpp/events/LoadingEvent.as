package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class LoadingEvent extends Event
	{
		public static const BUDDIES_LOADING:String = "buddiesLoading";
		public static const BUDDIES_LOADED:String = "buddiesLoaded";

		public static const WORKSTREAM_LOADING:String = "messagesLoading";
		public static const WORKSTREAM_LOADED:String = "messagesLoaded";
		
		public static const CHAT_LOADED:String = "chatLoaded";
		public static const CHATS_LOADING:String = "chatsLoading";
		public static const CHATS_LOADED:String = "chatsLoaded";

		public static const LOADING_COMPLETE:String = "loadingComplete";
		
		public var loaded:int;
		public var total:int;
		
		public function LoadingEvent(type:String, loaded:int=0, total:int=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.loaded = loaded;
			this.total = total;
		}
		
		override public function clone():Event
		{
			return new LoadingEvent(type, loaded, total, bubbles, cancelable);
		}
		
	}
}