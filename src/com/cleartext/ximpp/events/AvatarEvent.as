package com.cleartext.ximpp.events
{
	import flash.events.Event;

	public class AvatarEvent extends Event
	{
		public static const EDIT_CLICKED:String = "editClicked";
		
		public function AvatarEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new AvatarEvent(type, bubbles, cancelable);
		}
	}
}