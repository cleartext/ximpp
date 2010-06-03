package com.cleartext.ximpp.events
{
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.Event;

	public class UserAccountEvent extends Event
	{
		public static const CHANGED:String = "userAccountChanged";
		public static const REFRESH:String = "userAccountRefresh";
		public static const PASSWORD_CHANGE:String = "passwordChange";
		
		public var previousUserAccount:UserAccount;
		public var newPassword:String;
		
		public function UserAccountEvent(type:String, previousUserAccount:UserAccount, newPassword:String="", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.previousUserAccount = previousUserAccount;
			this.newPassword = newPassword;
		}
		
		override public function clone():Event
		{
			return new UserAccountEvent(type, previousUserAccount);
		}
	}
}