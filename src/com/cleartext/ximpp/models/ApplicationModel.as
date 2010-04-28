package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.events.UserAccountEvent;
	import com.cleartext.ximpp.models.utils.LinkUitls;
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
	import flash.utils.setTimeout;
	
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
			database.createDatabase();

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
			
			buddies.buddies.addItem(Buddy.ALL_MICRO_BLOGGING_BUDDY);
			buddies.refresh();
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
			setTimeout(getChat, 1, Buddy.ALL_MICRO_BLOGGING_BUDDY);
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
				var message:Message = createFromStanza(messageStanza);
				
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
		
		public function createFromStanza(stanza:MessageStanza):Message
		{
			var newMessage:Message = new Message();

			newMessage.sender = stanza.from.getBareJID();
			newMessage.recipient = stanza.to.getBareJID();
			newMessage.type = stanza.type;
			newMessage.subject = stanza.subject;
			newMessage.plainMessage = stanza.body;
			newMessage.rawXML = stanza.xmlstring;
			var date:Date = stanza.utcTimestamp;
			newMessage.utcTimestamp = date;
			newMessage.timestamp = new Date(Date.UTC(date.fullYear, date.month, date.date, date.hours, date.minutes, date.seconds, date.milliseconds));
			
			var linkVals:Array;
			
			var customTags:Array = stanza.customTags;
			if(customTags && customTags.length > 0)
			{
				for each(var x:XML in customTags)
				{
					for each(var n:Namespace in x.namespaceDeclarations())
					{
						// first check if it has the cleartext custom tags
						if(n.uri == "http://cleartext.net/mblog")
						{
							var sBuddy:Object = x.*::buddy.(@type=="sender");

							if(sBuddy.*::jid != mBlogBuddies.userAccount.jid)
							{
								newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(
										String(sBuddy.*::userName), sBuddy.*::serviceJid, 
										sBuddy.*::displayName, sBuddy.*::avatar.(@type=='url'),
										sBuddy.*::jid, sBuddy.*::avatar.(@type=='hash'));
							}
							
							var osBuddy:Object = x.*::buddy.(@type=="originalSender");

							if(osBuddy)
							{
								newMessage.mBlogOriginalSender = mBlogBuddies.getMicroBloggingBuddy(
										String(osBuddy.*::userName), osBuddy.*::serviceJid, 
										osBuddy.*::displayName, osBuddy.*::avatar.(@type=='url'),
										osBuddy.*::jid, osBuddy.*::avatar.(@type=='hash'));
							}
							
							var text:String = x.*::text;
							if(text)
								newMessage.plainMessage = text;
						}
						
						// if it has an atom, then it is probably jaiku or identi.ca
						if(n.uri == "http://www.w3.org/2005/Atom")
						{
							namespace atom = "http://www.w3.org/2005/Atom";
							var idString:String;
							var displayName:String;
							var avatarUrl:String;
							var list:XMLList;
							
							list = x.atom::author;
							if(list && list.length()>0)
								idString = list[0].atom::name;
						
							list = x.atom::source;
							if(list && list.length()>0)
								avatarUrl = list[0].atom::icon;
							// nasty hack cause jaiku gives us the WRONG url for the image
							// we have to replace the _None.jpg with _f.jpg
							if(avatarUrl.substr(-9,9) == "_None.jpg")
								avatarUrl = avatarUrl.substr(0, avatarUrl.length-9) + "_f.jpg";
							
							list = x.*::actor;
							if(list && list.length()>0)
								displayName = list[0].atom::title;
							// jaiku also doesn't give us a display name, so make sure it is an
							// empty string and not null put an empty string in the db
							if(!displayName)
								displayName = "";
								
							newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(idString, newMessage.sender, displayName, avatarUrl);
						
							// if there is a title on the atom, then it should be just the plain message
							if(x.atom::title)
							{
								newMessage.plainMessage = x.atom::title;
								switch(newMessage.sender)
								{
									case "jaiku@jaiku.com" :
										linkVals = ["http://www.jaiku.com/channel/", "", "http://", ".jaiku.com/"];
										break;
									case "update@identi.ca" :
										linkVals = ["http://identi.ca/tag/", "", "http://identi.ca/", ""];
										break;
								}
							}
						}
					}
				}
			}
			
			// if there are no valid link vals and there is an html string, then have a go at parsing it
			if(!linkVals && stanza.html)
			{
				var regexpString:String =
					"<img src=('|\")" + 		// open img tag with src=" or src='
					"([\\s\\S]*?)" + 			// image url - result[2]
					"\\1" +			 			// the closing " or '
					"[\\s\\S]*?" + 				// a lazy amount of any chars
					"<a[\\s\\S]*?>" + 			// a open a tag with any kind of href 
					"([\\s\\S]*?)<" + 			// the text within the a tag - the display name - result[3]
					"[\\s\\S]*?" + 				// a lazy amount of any chars
					"\\(([\\s\\S]*?)\\): ?" + 	// text within (): - the user id - result[4]
					"([\\s\\S]*?)" + 			// a lazy amount of any chars - the message - result[5]
					"</span>";					// the closing span tag
				
				var regexp:RegExp = new RegExp(regexpString, "ig");
				var result:Array = regexp.exec(stanza.html);

				if(result && result.length > 0)
				{
					newMessage.mBlogSender = mBlogBuddies.getMicroBloggingBuddy(result[4], newMessage.sender, result[3], result[2]);
					newMessage.plainMessage = String(result[5]);
					linkVals = ["http://twitter.com/search?q=%23", "", "http://twitter.com/", ""];
				}
			}
			
			if(linkVals)
				newMessage.displayMessage = LinkUitls.createLinks(newMessage.plainMessage, linkVals[0], linkVals[1], linkVals[2], linkVals[3]);
			else if(stanza.html)
				newMessage.displayMessage = stanza.html;
			else
				newMessage.displayMessage = LinkUitls.createLinks(newMessage.plainMessage);

			return newMessage;
		}
	}	
}