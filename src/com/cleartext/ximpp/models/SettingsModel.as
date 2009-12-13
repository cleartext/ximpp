package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.Event;
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
		public function set userAccount(value:UserAccount):void
		{
			if(value != _userAccount)
			{
				_userAccount = value;
				appModel.userAccountChanged();
				dispatchEvent(new Event("userAccountChanged"));
			}
		}
		
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
	}
}