package com.cleartext.esm.events
{
	import flash.events.Event;
	
	public class LinkEvent extends Event
	{
		public static const LINK_CLICKED:String = "linkClicked";
		public static const LINK_RESULT:String = "linkResult";
		
		public var url:String;
		public var result:Object;
	
		public function LinkEvent(type:String, url:String=null, result:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.url = url;
			this.result = result;
		}
		
		override public function clone():Event
		{
			return new LinkEvent(type, url, result, bubbles, cancelable);
		}
	}
	
}