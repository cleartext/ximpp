package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.Event;

	public class PopUpEvent extends Event
	{
		public static const PREFERENCES_WINDOW:String = "preferencesWindow";
		public static const ADVANCED_SEARCH_WINDOW:String = "advancedSearchWindow";

		public static const SUBSCRIPTION_REQUEST_WINDOW:String = "subscriptionRequestWindow";

		public static const BUDDY_NOT_IN_ROSTER_WINDOW:String = "buddyNotInRosterWindow";

		public static const ADD_GATEWAY_WINDOW:String = "addGatewayWindow";

		public static const ADD_BUDDY_WINDOW:String = "addBuddyWindow";
		public static const EDIT_BUDDY_WINDOW:String = "editBuddyWindow";
		public static const DELETE_BUDDY_WINDOW:String = "deleteBuddyWindow";

		public static const ADD_GROUP_WINDOW:String = "addGroupWindow";
		public static const EDIT_GROUP_WINDOW:String = "editGroupWindow";
		public static const DELETE_GROUP_WINDOW:String = "deleteGroupWindow";

		public static const ADD_MICRO_BLOGGING_WINDOW:String = "addMicroBloggingWindow";
		public static const SEND_TO_ALL_MICRO_BLOGGING_WINDOW:String = "sendToAllMicroBloggingWindow";

		public static const XML_INPUT_WINDOW:String = "xmlInputWindow";
		
		public var group:String;
		public var buddy:Buddy;
		
		public function PopUpEvent(type:String, group:String="", buddy:Buddy=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.group = group;
			this.buddy = buddy;
		}
		
		override public function clone():Event
		{
			return new PopUpEvent(type, group, buddy, bubbles, cancelable);
		}
	}
}