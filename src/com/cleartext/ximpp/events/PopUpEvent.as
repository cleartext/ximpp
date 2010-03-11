package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.Event;

	public class PopUpEvent extends Event
	{
		public static const PREFERENCES_WINDOW:String = "preferencesWindow";
		public static const ADVANCED_SEARCH_WINDOW:String = "advancedSearchWindow";

		public static const SUBSCRIPTION_REQUEST_WINDOW:String = "subscriptionRequestWindow";

		public static const ADD_GATEWAY_WINDOW:String = "addGatewayWindow";

		public static const ADD_BUDDY_WINDOW:String = "addBuddyWindow";
		public static const EDIT_BUDDY_WINDOW:String = "editBuddyWindow";
		public static const DELETE_BUDDY_WINDOW:String = "deleteBuddyWindow";

		public static const ADD_GROUP_WINDOW:String = "addGroupWindow";
		public static const EDIT_GROUP_WINDOW:String = "editGroupWindow";
		public static const DELETE_GROUP_WINDOW:String = "deleteGroupWindow";

		public static const ADD_MICRO_BLOGGING_WINDOW:String = "addMicroBloggingWindow";
//		public static const EDIT_MICRO_BLOGGING_WINDOW:String = "editMicroBloggingWindow";
//		public static const DELETE_MICRO_BLOGGING_WINDOW:String = "deleteMicroBloggingWindow";
		
		public var dataString:String;
		public var buddy:Buddy;
		
		public function PopUpEvent(type:String, dataString:String="", buddy:Buddy=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.dataString = dataString;
			this.buddy = buddy;
		}
		
		override public function clone():Event
		{
			return new PopUpEvent(type, dataString, buddy, bubbles, cancelable);
		}
	}
}