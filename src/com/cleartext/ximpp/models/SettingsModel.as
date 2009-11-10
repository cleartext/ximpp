package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.UrlShortener;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.events.EventDispatcher;
	
	public class SettingsModel extends EventDispatcher
	{
		public function SettingsModel()
		{
		}
		
		[Bindable (event="autoConnectChanged")]
		public var autoConnect:Boolean = false;

		public var urlShortener:String = UrlShortener.types[0];
		public var timelineTopDown:Boolean = false;
		public var chatTopDown:Boolean = false;

		[Bindable (event="userAccountChanged")]
		public var userAccount:UserAccount;
		
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
	}
}