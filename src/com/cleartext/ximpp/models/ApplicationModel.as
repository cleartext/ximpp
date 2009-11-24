package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Status;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.utils.ObjectUtil;
	
	public class ApplicationModel extends EventDispatcher
	{
		public static const SHOW_PREFERENCES_WINDOW:String = "showPreferencesWindow";
		public static const SHOW_ADVANCED_SEARCH_WINDOW:String = "showAdvancedSearchWindow";

		[Autowire]
		[Bindable]
		public var settings:SettingsModel;
		
		[Autowire]
		[Bindable]
		public var database:DatabaseModel;
		
		[Autowire]
		[Bindable]
		public var xmpp:XMPPModel;
		
		public function ApplicationModel()
		{
//			var sort:Sort = new Sort();
//			sort.compareFunction = compareBuddies;
//			buddies.sort = sort;
		}

		private var _buddyByJid:Dictionary = new Dictionary();
		public function get buddyByJid():Dictionary
		{
			return _buddyByJid;
		}
		
		private var _buddyCollection:ArrayCollection = new ArrayCollection();
		public function get buddyCollection():ArrayCollection
		{
			return _buddyCollection;
		}

		[Bindable]
		public var timeLineMessages:ArrayCollection = new ArrayCollection();

		[Bindable]
		public var selectedChat:Chat;
		
		public var chats:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		public var serverSideStatus:Status = new Status(Status.OFFLINE);
		
		[Bindable]
		public var localStatus:Status = new Status(Status.OFFLINE);
		
		[Bindable]
		public var showConsole:Boolean = true;

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
			localStatus.value = statusString;
	
			if(!settings.userAccount ||
				localStatus.value == serverSideStatus.value && 
				customStatus == settings.userAccount.customStatus)
				return;
			
			if(customStatus != settings.userAccount.customStatus)
			{
				settings.userAccount.customStatus = customStatus;
				database.saveUserAccount(settings.userAccount);
			}

			xmpp.sendPresence();
		}

		public function init():void
		{
			database.createDatabase();
			// if this changes the userId, it will reload all the data from the database
			database.loadGlobalSettings();
			if(!settings.userAccount.valid)
			{
				Alert.show(
					"There are no valid user settings stored. Do you want to change your preferences now?",
					 "Invalid User Settings", Alert.YES | Alert.NO, null,
					 function(event:CloseEvent):void
					 {
					 	if(event.detail == Alert.YES)
					 	{
					 		showPreferencesWindow();
					 	}
					 });
			}
			else if(settings.global.autoConnect)
			{
				setUserPresence(Status.AVAILABLE, settings.userAccount.customStatus);
			}

//			for(var i:int=0; i<10; i++)
//			{
//				var message:Message = new Message();
//				message.publisher = randomString(4,8) + "@" + randomString(4,8) + ".com";
//				message.htmlBody = randomString(40,140,4);
//				messages.addItem(message);
//			}
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
		
		public function getChat(buddy:Buddy):Chat
		{
			if(!buddy)
				return null;
			
			for each(var chat:Chat in chats)
			{
				if(chat.buddy == buddy)
					return chat;
			}
			var c:Chat = new Chat(buddy);
			c.messages = database.loadMessages(buddy);
			
			chats.addItem(c);
			return c;
		}
		
		public function selectChat(buddy:Buddy):Chat
		{
			var chat:Chat = getChat(buddy);
			selectedChat = chat;
			return chat;
		}
		
		public function getBuddyByJid(jid:String):Buddy
		{
			if(!jid || jid=="")
				return null;
				
			if(jid == settings.userAccount.jid)
				return settings.userAccount.toBuddy();
			
			return buddyByJid[jid];
		}
		
		public function showPreferencesWindow():void
		{
	 		dispatchEvent(new Event(SHOW_PREFERENCES_WINDOW));
		}
		
		public function showAdvancedSearchWindow():void
		{
			dispatchEvent(new Event(SHOW_ADVANCED_SEARCH_WINDOW));
		}
		
		private function compareBuddies(buddy1:Buddy, buddy2:Buddy, fields:Object=null):int
		{
			var nameCompare:int = ObjectUtil.compare(buddy1.nickName, buddy2.nickName);
			
			if(buddy1.status == buddy2.status)
				return nameCompare;
			
			else if(buddy1.status.value == Status.OFFLINE)
				return 1;
			else if(buddy2.status.value == Status.OFFLINE)
				return -1;
			
			return 0;
		}

		public function addBuddy(newBuddy:Buddy):void
		{
			var newId:int = database.saveBuddy(newBuddy);
			var oldBuddy:Buddy = buddyByJid[newBuddy.jid] as Buddy;

			if(newId == -1 && oldBuddy != null)
			{
				oldBuddy.fill(newBuddy);
				oldBuddy.used = true;
			}
			else
			{
				if(newId != -1)
					newBuddy.buddyId = newId;
	
				buddyByJid[newBuddy.jid] = newBuddy;
				buddyCollection.addItem(newBuddy);
				newBuddy.used = true;
			}
		}
		
		public function removeBuddy(buddy:Buddy):void
		{
			delete buddyByJid[buddy.jid];
			buddyCollection.removeItemAt(buddyCollection.getItemIndex(buddy));
			database.removeBuddy(buddy.buddyId);
		}

		public static function randomString(minLength:int, maxLength:int, caseStyle:int=0):String
		{
			/*
			 * 0 lowercase
			 * 1 uppercase
			 * 2 title case
			 * 3 sentence case
			 * 4 prose
			 */
			var upperCaseLetters:Array = ("ABCDEFGHIJKLMNOPQRSTUVWXYZ").split("");
			var lowerCaseLetters:Array = ("abcdefghijklmnopqrstuvwxyz").split("");
			var fullStop:String = ". ";
			var comma:String = ", ";
			var space:String = " ";
			var maxWordLength:int = 9;

			var length:int = Math.round(Math.random() * (maxLength-minLength) + minLength);
			var result:String = "";
			var char:String = space;
			var wordLength:int=0;
			for(var i:int=0; i<length; i++)
			{
				if((char == space && caseStyle==2) || char == fullStop)
				{
					char = randomItem(upperCaseLetters) as String;
					wordLength++;
				}
				else
				{
					var random:Number = Math.random();
					if(wordLength <= 2)
					{
						random += wordLength*0.04;
					}

					if(caseStyle >= 2 &&
						((wordLength > maxWordLength) || 
						(random < 0.15 && char != fullStop && char != space && char != comma)))
					{
						if(caseStyle == 4 && random < 0.01 && i<length-20 && i>20)
						{
							char = fullStop;
							i++;
						}
						else if(caseStyle == 4 && random < 0.02 && i<length-10 && i>10)
						{
							char = comma;
							i++;
						}
						else if(char != space && i<length-4)
						{
							char = space;
						}
						wordLength = 0;
					}
					else
					{
						var previousChar:String = char;
						while(previousChar == char)
						{
							char = randomItem(lowerCaseLetters) as String;
						}
						wordLength++;
					}
				}
				result += char;
			}
			
			if(caseStyle == 1)
			{
				result = result.toUpperCase();
			}
			else if(caseStyle >= 3)
			{
				result = result.slice(1,-1);
				result = (randomItem(upperCaseLetters) as String) + result + ".";
			}
			return result;
		}
				
		public static function randomItem(array:Array):Object
		{
			var index:int = Math.floor(Math.random() * array.length+1)-1;
			if(index == array.length)
				index --;
			return array[index];
		}
		
	}
}