package com.cleartext.ximpp.model
{
	import com.cleartext.ximpp.database.LocalDatabase;
	import com.cleartext.ximpp.model.valueObjects.Buddy;
	import com.cleartext.ximpp.model.valueObjects.Status;
	import com.cleartext.ximpp.model.valueObjects.UrlShortener;
	import com.cleartext.ximpp.model.valueObjects.UserAccount;
	import com.cleartext.ximpp.xmpp.XmppConnection;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	
	public class XModel extends EventDispatcher
	{
		public static const SHOW_PREFERENCES_WINDOW:String = "showPreferencesWindow";
		public static const SHOW_ADVANCED_SEARCH_WINDOW:String = "showAdvancedSearchWindow";
		
		static private var instance:XModel = new XModel();
		static public function getInstance():XModel
		{
			return instance;
		}
		
		// needs a custom event??
		[Bindable]
		public var logText:String = "";
		public function log(toLog:Object):void
		{
			var str:String = getTimer() + " : ";
			if(toLog is String)
			{
				str += toLog;
				logText += str + "\n";
				trace(str);
			}
			else if(toLog is Event)
			{
				var event:Event = toLog as Event;
				logText += str + event.type + "\n\t";
				trace(str + event);
			}
			else if(toLog is Error)
			{
				var error:Error = toLog as Error;
				logText += str + error.name + "\n\t";
				trace(str + error);
			}
		}
		
		public var localDatabase:LocalDatabase = new LocalDatabase();
		public var xmppConnection:XmppConnection = new XmppConnection();
		
		/**
		 * GLOBAL SETTINGS
		 */
		private var _autoConnect:Boolean = false;
		public function get autoConnect():Boolean
		{
			return _autoConnect;
		}
		public function set autoConnect(value:Boolean):void
		{
			if(_autoConnect != value)
			{
				_autoConnect = value;
				if(_autoConnect && !xmppConnection.connected)
				{
					xmppConnection.connect();
				}
			}
		}
		public var urlShortener:String = UrlShortener.types[0];
		public var timelineTopDown:Boolean = false;
		public var chatTopDown:Boolean = false;
		public function get userId():int
		{
			return (userAccount) ? userAccount.userId : -1;
		}
		
		[Bindable (event="serverSideStatusChanged")]
		private var _serverSideStatus:String = Status.OFFLINE;
		public function get serverSideStatus():String
		{
			return _serverSideStatus;
		}
		public function set serverSideStatus(value:String):void
		{
			if(_serverSideStatus != value)
			{
				_serverSideStatus = value;
				dispatchEvent(new Event("serverSideStatusChanged"));
			}
		}
		public var localStatus:String = Status.OFFLINE;
		
		/**
		 * USER ACCOUNT, BUDDIES, MESSAGES, CHATS
		 */
		 
		private var _userAccount:UserAccount;
		[Bindable (event="userAccountChanged")]
		public function get userAccount():UserAccount
		{
			return _userAccount;
		}
		public function set userAccount(value:UserAccount):void
		{
			if(_userAccount != value)
			{
				_userAccount = value;
				dispatchEvent(new Event("userAccountChanged"));
			}
		}
		[Bindable (event="buddiesChanged")]
		public var buddies:ArrayCollection = new ArrayCollection();
		[Bindable (event="messagesChanged")]
		public var messages:ArrayCollection = new ArrayCollection();
		[Bindable (event="chatsChanged")]
		public var chats:ArrayCollection = new ArrayCollection();
		
		public function XModel()
		{
			if(instance) throw new Error("XModel is a singleton and can only be accessed through XModel.getInstance()");
		}
		
		public function init():void
		{
			localDatabase.createDatabase();
			// if this changes the userId, it will reload all the data from the database
			localDatabase.loadGlobalSettings();
			if(!userAccount)
			{
				Alert.show(
					"There are no user settings stored, you need to add at least one account to start using ximpp. Do you want to create a new account now?",
					 "No User Settings", Alert.YES | Alert.NO, null,
					 function(event:CloseEvent):void
					 {
					 	if(event.detail == Alert.YES)
					 	{
					 		showPreferencesWindow();
					 	}
					 });
			}
			else if(autoConnect)
			{
				xmppConnection.connect();
			}
		}
		
		public function shutDown():void
		{
			xmppConnection.disconnect();
			localDatabase.close();
		}
		
		public function fatalError(errorMsg:String=""):void
		{
			Alert.show("Sorry, there has been a fatal error, please quit ximpp.\n" + errorMsg, "Fatal Error", 4, null,
				function():void
				{
					Application.application.exit();
				});
		}
		
		public function showPreferencesWindow():void
		{
	 		dispatchEvent(new Event(SHOW_PREFERENCES_WINDOW));
		}
		
		public function showAdvancedSearchWindow():void
		{
			dispatchEvent(new Event(SHOW_ADVANCED_SEARCH_WINDOW));
		}
		
		public function addBuddy(buddy:Buddy):void
		{
			var newId:int = localDatabase.saveBuddy(buddy);

			if(newId != -1)
				buddy.buddyId = newId;

			buddies.addItem(buddy);
			buddies.refresh();
		}
		
		public function setUserPresence(status:String, customStatus:String):void
		{
			localStatus = status;
			
			if(!userAccount ||
				localStatus == serverSideStatus && 
				customStatus == userAccount.customStatus)
				return;
			
			dispatchEvent(new Event("serverSideStatusChanged"));
			
			if(customStatus != userAccount.customStatus)
			{
				userAccount.customStatus = customStatus;
				localDatabase.saveUserAccount(userAccount);
			}

			xmppConnection.sendPresence();
		}
	}
}