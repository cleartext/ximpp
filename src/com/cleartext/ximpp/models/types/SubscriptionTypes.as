package com.cleartext.ximpp.models.types
{
	public class SubscriptionTypes
	{
		public static const NONE:String = "none";
		public static const TO:String = "to";
		public static const FROM:String = "from";
		public static const BOTH:String = "both";
		public static const REMOVE:String = "remove";
		
		// sender wants to subscribe to recepient
		public static const SUBSCRIBE:String = "subscribe";

		// sender wants to publish status to recipient
		public static const SUBSCRIBED:String = "subscribed";

		// sender no longer wants to receive status updates
		// from recipient (should be handled by the server 
		// when removing buddies from roster list)
		public static const UNSUBSCRIBE:String = "unsubscribe";

		// the sencder no longer wants to publish their
		// status to the recipient
		public static const UNSUBSCRIBED:String = "unsubscribed";
	}
}