package com.cleartext.esm.events
{
	import flash.events.Event;

	public class XmppErrorEvent extends Event
	{
		public static const ERROR:String = "error";
		
		public var message:String;
		public var fromJid:String;
		public var errorXML:XML;
		
		public function XmppErrorEvent(type:String, message:String, formJid:String, errorXML:XML, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.message = message;
			this.fromJid = fromJid;
			this.errorXML = errorXML;
		}
		
		override public function clone():Event
		{
			return new XmppErrorEvent(type, message, fromJid, errorXML, bubbles, cancelable);
		}
		
	}
}