package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.events.UserAccountEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.seesmic.as3.xmpp.MessageStanza;
	import com.seesmic.as3.xmpp.StreamEvent;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	
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
		
		[Autowire]
		[Bindable]
		public var buddies:BuddyModel;
		
		[Autowire]
		[Bindable]
		public var mBlogBuddies:MicroBloggingModel;
		
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
		[Bindable (event="changed")]
		public function get localStatus():Status
		{
			return _localStatus;
		}
		
		private var lastStatus:String;
		
		[Bindable]
		public var showConsole:Boolean = false;

		[Bindable (event="xmlConsoleTextChanged")]
		public var xmlConsoleText:String = "";
		public function resetXmlConsole():void
		{
			xmlConsoleText = "";
			dispatchEvent(new Event("xmlConsoleTextChanged"));
		}
		public function xmlStreamHandler(event:StreamEvent):void
		{
			if(!xmlConsoleEnabled || event.data == "")
				return;
			
			xmlConsoleText += getTimer() + " " ;
			
			if(event.type == StreamEvent.COMM_OUT)
				xmlConsoleText += "OUT :";
			else
				xmlConsoleText += "IN :";
			
			xmlConsoleText += "\n" + event.data + "\n\n";
			dispatchEvent(new Event("xmlConsoleTextChanged"));
		}
		
		[Bindable]
		public var xmlConsoleEnabled:Boolean = false;

		[Bindable]
		public var logEnabled:Boolean = false;

		[Bindable (event="logTextChanged")]
		public var logText:String = "";
		public function resetLog():void
		{
			logText = "";
			dispatchEvent(new Event("logTextChanged"));
		}
		public function log(toLog:Object):void
		{
			var str:String = getTimer() + " : ";
			var traceStr:String = getTimer() + " : ";

			if(toLog is String)
			{
				str += toLog;
				traceStr += toLog;
			}
			else if(toLog is Event)
			{
				var event:Event = toLog as Event;
				str += event.type;
				traceStr += event.toString();
			}
			else if(toLog is Error)
			{
				var error:Error = toLog as Error;
				str += error.name;
				traceStr += error.toString();
			}

			if(logEnabled)
			{
				logText += str + "\n";
				dispatchEvent(new Event("logTextChanged"));
			}

			trace(traceStr);
		}
		
		public function ApplicationModel()
		{
			super();
			var nApp:NativeApplication = NativeApplication.nativeApplication;
			nApp.idleThreshold = 360;
			nApp.addEventListener(Event.USER_IDLE, userHandler);
			nApp.addEventListener(Event.USER_PRESENT, userHandler);
		}
		
		private function userHandler(event:Event):void
		{
			if(!xmpp.connected)
				return;

			if(event.type == Event.USER_IDLE)
			{
				lastStatus = localStatus.value;
				setUserPresence(Status.AWAY, settings.userAccount.customStatus)
			}
			else if(event.type == Event.USER_PRESENT)
			{
				setUserPresence(lastStatus, settings.userAccount.customStatus)
			}
		}	
			
		public function setUserPresence(statusString:String, customStatus:String):void
		{
			// check this is a value that can be set by a user 
			// (ie. OFFLINE, AVAILABLE, BUSY, AWAY)
			if(Status.USER_TYPES.indexOf(statusString) != -1)
				localStatus.value = statusString;
	
			// if there is no user account, or there is no change
			// in the status or customStatus, then return
			if(!settings.userAccount ||
				localStatus.value == serverSideStatus.value && 
				customStatus == settings.userAccount.customStatus)
				return;
			
			// save the customStatus
			if(customStatus != settings.userAccount.customStatus)
			{
				settings.userAccount.customStatus = customStatus;
				database.saveUserAccount(settings.userAccount);
			}

			// send the presence stanza
			xmpp.sendPresence();
		}

		public function init():void
		{
			database.addEventListener(Event.COMPLETE, databaseCompleteHandler);
			database.createDatabase();
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
		
		[Mediate(event="UserAccountEvent.CHANGED")]
		public function userIdChanged(event:UserAccountEvent):void
		{
			chats.removeAll();
			database.loadBuddyData();
			getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY);
		}
		
		public function getBuddyByJid(jid:String):Buddy
		{
			if(!jid || jid=="")
				return null;
				
			if(jid == settings.userAccount.jid)
				return settings.userAccount;
			
			return buddies.getBuddyByJid(jid);
		}
				
		public function getChat(buddy:Buddy):Chat
		{
			if(!buddy)
				return null;
			
			for each(var c:Chat in chats)
				if(c.buddy.jid == buddy.jid)
					return c;

			var chat:Chat = new Chat(buddy);
			chat.messages = database.loadMessages(buddy);
			chats.addItem(chat);
			return chat;
		}
		
		public function sendMessageTo(buddy:Buddy, messageString:String):void
		{
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
			{
				Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.SEND_TO_ALL_MICRO_BLOGGING_WINDOW, messageString));
			}
			else
			{
				var customTags:Array = new Array();

				if(buddy.microBlogging)
				{
					var userName:String = settings.userAccount.jid;
					userName = userName.substr(0, userName.indexOf("@"));
					var x:XML = <x xmlns='http://cleartext.net/mblog'/>;
					var b:XML = <buddy type='sender'/>;
					b.appendChild(<displayName>{settings.userAccount.nickName}</displayName>);
					b.appendChild(<userName>{userName}</userName>);
					b.appendChild(<jid>{settings.userAccount.jid}</jid>);
					if(settings.userAccount.avatarHash)
						b.appendChild(<avatar type='hash'>{settings.userAccount.avatarHash}</avatar>);
					b.appendChild(<serviceJid>{buddy.jid}</serviceJid>);
					x.appendChild(b);
					customTags.push(x);
				}

				var messageStanza:MessageStanza = xmpp.sendMessage(buddy.fullJid, messageString, null, 'chat', null, customTags);
				var message:Message = Message.createFromStanza(messageStanza, mBlogBuddies);
				
				var c:Chat = getChat(buddy);
				c.messages.addItemAt(message,0);
				
				if(buddy.microBlogging)
				{
					c = getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY);
					c.messages.addItemAt(message,0);
				}

				database.saveMessage(message);
			}
		}
	}
}