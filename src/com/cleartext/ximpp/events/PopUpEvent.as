package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.events.Event;

	public class PopUpEvent extends Event
	{
		public static const PREFERENCES_WINDOW:String = "preferencesWindow";
		public static const SEARCH_WINDOW:String = "searchWindow";
		public static const XML_INPUT_WINDOW:String = "xmlInputWindow";

		public static const ADD_GATEWAY_WINDOW:String = "addGatewayWindow";

		public static const JOIN_GROUP_CHAT:String = "joinGroupChatWindow";

		public static const ADD_BUDDY_WINDOW:String = "addBuddyWindow";
		public static const EDIT_BUDDY_WINDOW:String = "editBuddyWindow";
		public static const DELETE_BUDDY_WINDOW:String = "deleteBuddyWindow";
		public static const SUBSCRIPTION_REQUEST_WINDOW:String = "subscriptionRequestWindow";

		public static const ADD_GROUP_WINDOW:String = "addGroupWindow";
		public static const EDIT_GROUP_WINDOW:String = "editGroupWindow";
		public static const DELETE_GROUP_WINDOW:String = "deleteGroupWindow";

		public static const BROADCAST_WINDOW:String = "broadcastWindow";
		public static const NEW_CHAT_WITH_GROUP:String = "newChatWithGroup";

		public static const CHANGE_PASSWORD_WINDOW:String = "changePasswordWindow";
		
		public var buddy:Buddy;
		public var group:String;
		public var presenceRequest:Boolean = false;
		public var messageString:String;
		
		public function PopUpEvent(type:String)
		{
			super(type);
		}
		
		override public function clone():Event
		{
			var event:PopUpEvent = new PopUpEvent(type);
			event.buddy = buddy;
			event.group = group;
			event.presenceRequest = presenceRequest;
			event.messageString = messageString;
			return event;
		}
	}
}