package com.cleartext.esm.events
{
	import flash.events.Event;

	public class InputTextEvent extends Event
	{
		public static const INSERT_TEXT:String = "insertText";
		
		public var text:String;
		
		public function InputTextEvent(type:String, text:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.text = text;
		}
		
		override public function clone():Event
		{
			return new InputTextEvent(type, text, bubbles, cancelable);
		}
		
	}
}