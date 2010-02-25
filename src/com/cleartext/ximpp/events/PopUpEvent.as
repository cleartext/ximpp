package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.Event;

	public class PopUpEvent extends Event
	{
		public static const PREFERENCES_WINDOW:String = "preferencesWindow";
		public static const ADVANCED_SEARCH_WINDOW:String = "advancedSearchWindow";
		public static const ADD_NEW_BUDDY_WINDOW:String = "addNewBuddyWindow";
		public static const REMOVE_BUDDY_WINDOW:String = "removeBuddyWindow";
		public static const SUBSCRIPTION_REQUEST_WINDOW:String = "subscriptionRequestWindow";
		public static const EDIT_BUDDY_WINDOW:String = "editBuddyWindow";
		
		public var jid:String;
		public var buddy:Buddy;
		
		public function PopUpEvent(type:String, jid:String="", buddy:Buddy=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.jid = jid;
			this.buddy = buddy;
		}
		
		override public function clone():Event
		{
			return new PopUpEvent(type, jid, buddy, bubbles, cancelable);
		}
	}
}