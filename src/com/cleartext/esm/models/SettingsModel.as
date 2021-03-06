package com.cleartext.esm.models
{
	import com.cleartext.esm.events.UserAccountEvent;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.GlobalSettings;
	import com.cleartext.esm.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	
	import org.swizframework.Swiz;
	
	public class SettingsModel extends EventDispatcher
	{
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		public function SettingsModel()
		{
			super();
		}
		
		[Bindable]
		public var global:GlobalSettings = new GlobalSettings();

		private var _userAccount:UserAccount;
		[Bindable (event="userAccountChanged")]
		public function get userAccount():UserAccount
		{
			return _userAccount;
		}
		public function set userAccount(newUserAccount:UserAccount):void
		{
			var previousUserAccount:UserAccount = userAccount;
			
			_userAccount = newUserAccount;
			
			if(!previousUserAccount || newUserAccount.userId != previousUserAccount.userId)
			{
				var event:UserAccountEvent = new UserAccountEvent(UserAccountEvent.CHANGED, previousUserAccount);
				Swiz.dispatchEvent(event);
				dispatchEvent(event);
			}
			
			if(userAccount)
			{
				Swiz.dispatchEvent(new UserAccountEvent(UserAccountEvent.REFRESH, null));
			}
		}
		
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
	}
}