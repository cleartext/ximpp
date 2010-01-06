package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.Event;

	public class UserAccountEvent extends Event
	{
		public static const CHANGED:String = "userAccountChanged";
		
		public var previousUserAccount:UserAccount;
		
		public function UserAccountEvent(previousUserAccount:UserAccount, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(CHANGED, bubbles, cancelable);
			this.previousUserAccount = previousUserAccount;
		}
		
		override public function clone():Event
		{
			return new UserAccountEvent(previousUserAccount);
		}
	}
}