package com.cleartext.esm.events
{
	import flash.events.Event;

	public class AvatarEvent extends Event
	{
		public static const EDIT_CLICKED:String = "editClicked";
		public static const BITMAP_DATA_CHANGE:String = "bitmapDataChange";
		public static const SAVE:String = "save";
		public static const MBLOG_VALUES_CHANGE:String = "mblogValuesChange";
		
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