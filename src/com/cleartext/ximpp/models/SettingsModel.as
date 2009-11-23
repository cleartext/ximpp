package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	
	public class SettingsModel extends EventDispatcher
	{
		public function SettingsModel()
		{
		}
		
		public var global:GlobalSettings = new GlobalSettings();

		[Bindable (event="userAccountChanged")]
		public var userAccount:UserAccount;
		
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
	}
}