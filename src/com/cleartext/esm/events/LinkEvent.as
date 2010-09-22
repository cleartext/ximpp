package com.cleartext.esm.events
{
	import flash.events.Event;
	
	public class LinkEvent extends Event
	{
		public static const LINK_CLICKED:String = "linkClicked";
		public static const LINK_RESULT:String = "linkResult";
		
		public static const REDIRECT:String = "redirect";
		public static const OK:String = "ok";
		public static const ERROR:String = "error";
		
		public var urlOrMessage:String;
		public var status:String;
		public var id:int;
	
		public function LinkEvent(type:String, urlOrMessage:String=null, status:String=null, id:int=-1, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.urlOrMessage = urlOrMessage;
			this.status = status;
			this.id = id;
		}
		
		override public function clone():Event
		{
			return new LinkEvent(type, urlOrMessage, status, id, bubbles, cancelable);
		}
	}
	
}