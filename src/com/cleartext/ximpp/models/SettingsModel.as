package com.cleartext.ximpp.models
{
	import adobe.utils.CustomActions;
	
	import com.cleartext.ximpp.events.UserAccountEvent;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	
	public class SettingsModel extends EventDispatcher
	{
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		public function SettingsModel()
		{
		}
		
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
				appModel.userIdChanged();
			}
			dispatchEvent(new UserAccountEvent(previousUserAccount));
		}
		
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
	}
}