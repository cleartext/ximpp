package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.BuddyGroup;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Status;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.utils.ObjectUtil;
	
	import org.swizframework.Swiz;
	
	public class ApplicationModel extends EventDispatcher
	{
		[Autowire]
		[Bindable]
		public var settings:SettingsModel;
		
		[Autowire]
		[Bindable]
		public var database:DatabaseModel;
		
		[Autowire]
		[Bindable]
		public var xmpp:XMPPModel;
		
		[Bindable]
		public var rosterItems:BuddyGroup = new BuddyGroup("roster items");
		
		[Bindable]
		public var microBloggingMessages:ArrayCollection = new ArrayCollection();

		[Bindable]
		public var chats:ArrayCollection = new ArrayCollection();
		
		/*
		 * SERVER SIDE STATUS
		 * This variable stores the state that the server has for us based on
		 * the last communication with the server.
		 */
		[Bindable]
		public var serverSideStatus:Status = new Status(Status.OFFLINE);
		
		/*
		 * LOCAL STATUS
		 * This is the status that the user selects.
		 */
		private var _localStatus:Status = new Status(Status.OFFLINE);
		public function get localStatus():Status
		{
			return _localStatus;
		}
		
		[Bindable]
		public var showConsole:Boolean = false;

		[Bindable (event="logTextChanged")]
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
			dispatchEvent(new Event("logTextChanged"));
		}
		
		public function setUserPresence(statusString:String, customStatus:String):void
		{
			if(Status.USER_TYPES.indexOf(statusString) != -1)
				localStatus.value = statusString;
	
			if(!settings.userAccount ||
				localStatus.value == serverSideStatus.value && 
				customStatus == settings.userAccount.customStatus)
				return;
			
			if(customStatus != settings.userAccount.customStatus)
			{
				settings.userAccount.setCustomStatus(customStatus);
				database.saveUserAccount(settings.userAccount);
			}

			xmpp.sendPresence();
		}

		public function init():void
		{
			database.addEventListener(Event.COMPLETE, databaseCompleteHandler);
			database.createDatabase();
			
			var sort:Sort = new Sort();
			sort.compareFunction = compareBuddies;
			rosterItems.sort = sort;
			rosterItems.refresh();
		}
		
		private function databaseCompleteHandler(event:Event):void
		{
			database.removeEventListener(Event.COMPLETE, databaseCompleteHandler);

			// if this changes the userId, it will reload all the data from the database
			database.loadGlobalSettings();
			if(!settings.userAccount.valid)
			{
				Alert.show(
					"There are no valid settings selected. Do you want to change your preferences now?",
					 "Invalid User Settings", Alert.YES | Alert.NO, null,
					 function(event:CloseEvent):void
					 {
					 	if(event.detail == Alert.YES)
					 		Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.PREFERENCES_WINDOW));
					 });
			}
			else if(settings.global.autoConnect)
			{
				setUserPresence(Status.AVAILABLE, settings.userAccount.customStatus);
			}
		}
		
		public function shutDown():void
		{
			xmpp.disconnect();
			database.close();
		}
		
		public function fatalError(errorMsg:String=""):void
		{
			Alert.show("Sorry, there has been a fatal error, please quit ximpp.\n" + errorMsg, "Fatal Error", 4, null,
				function():void
				{
					Application.application.exit();
				});
		}
		
		public function userIdChanged():void
		{
			chats.removeAll();
			microBloggingMessages.removeAll();
			rosterItems.removeAll();

			var chat:Chat = new Chat(new Buddy("microBlogging"));
			chat.messages = microBloggingMessages;
			chats.addItem(chat);
			
			database.loadBuddyData();
			database.loadMicroBloggingData();
		}
		
		public function getChat(buddy:Buddy, select:Boolean=true):Chat
		{
			if(!buddy)
				return null;
			
			for each(var c:Chat in chats)
			{
				if(c.buddy == buddy)
				{
					if(select)
						Swiz.dispatchEvent(new ChatEvent(ChatEvent.SELECT_CHAT, c));
					return c;
				}
			}

			var chat:Chat = new Chat(buddy);
			chat.messages = database.loadMessages(buddy);
			chats.addItem(chat);
			return chat;
		}
		
		public function getBuddyByJid(jid:String):Buddy
		{
			if(!jid || jid=="")
				return null;
				
			if(jid == settings.userAccount.jid)
				return settings.userAccount;
			
			return rosterItems.getBuddy(jid);
		}
		
		private function compareBuddies(buddy1:Buddy, buddy2:Buddy, fields:Object=null):int
		{
			var statusCompare:int = buddy1.status.sortNumber() - buddy2.status.sortNumber();

			if(statusCompare == 0)
				return ObjectUtil.compare(buddy1.nickName, buddy2.nickName);
			else
				return (statusCompare > 0) ? 1 : -1;
		}

		public function addBuddy(newBuddy:Buddy):void
		{
			rosterItems.addBuddy(newBuddy);
			newBuddy.addEventListener(BuddyEvent.CHANGED, buddySaveHandler);
			database.saveBuddy(newBuddy);
		}
		
		private function buddySaveHandler(event:BuddyEvent):void
		{
			database.saveBuddy(event.target as Buddy);
		}
		
		public function removeBuddy(buddy:Buddy):void
		{
			rosterItems.removeBuddy(buddy);
			database.removeBuddy(buddy.buddyId);
			buddy.removeEventListener(BuddyEvent.CHANGED, buddySaveHandler);
		}

	}
}