package com.cleartext.ximpp.events
{
	import flash.events.Event;
	
	public class HasAvatarEvent extends Event
	{
		public static const AVATAR_CHANGE:String = "avatarChange";
		public static const CHANGE_DISPLAY:String = "changeDisplay";
		public static const CHANGE_SAVE:String = "changeSave";

		public function HasAvatarEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return new HasAvatarEvent(type, bubbles, cancelable);
		}
	}
}