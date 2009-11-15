package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Message;
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
			var sort:Sort = new Sort();
			sort.compareFunction = compareBuddies;
			buddies.sort = sort;
			
			buddies.refresh();
		}

		[Bindable]
		public var buddies:ArrayCollection = new ArrayCollection();
		[Bindable]
		public var messages:ArrayCollection = new ArrayCollection();
		[Bindable]
		public var chats:ArrayCollection = new ArrayCollection();
		
		[Bindable]
		public var serverSideStatus:String = Status.OFFLINE;
		
		public var localStatus:String = Status.OFFLINE;

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
		
		public function setUserPresence(status:String, customStatus:String):void
		{
			localStatus = status;
			
			if(!settings.userAccount ||
				localStatus == serverSideStatus && 
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
			if(!settings.userAccount)
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
			else if(settings.autoConnect)
			{
				setUserPresence(Status.AVAILABLE, settings.userAccount.customStatus);
			}

			for(var i:int=0; i<10; i++)
			{
				var message:Message = new Message();
				message.publisher = randomString(4,8) + "@" + randomString(4,8) + ".com";
				message.htmlBody = randomString(40,140,4);
				messages.addItem(message);
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
			
			else if(buddy1.status == Status.OFFLINE)
				return 1;
			else if(buddy2.status == Status.OFFLINE)
				return -1;
			
			return 0;
		}

		public function addBuddy(newBuddy:Buddy):void
		{
			var newId:int = database.saveBuddy(newBuddy);

			if(newId == -1)
			{
				var success:Boolean = false;
				for each(var testBuddy:Buddy in buddies)
				{
					if(testBuddy.buddyId == newBuddy.buddyId)
					{
						success = true;
						testBuddy.fill(newBuddy);
						break;
					}
				}
			}
			else
			{
				newBuddy.buddyId = newId;
				buddies.addItem(newBuddy);
			}
			buddies.refresh();
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