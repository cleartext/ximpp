package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.models.types.IQTypes;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.utils.AvatarUtils;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.MicroBloggingBuddy;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSEvent;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.seesmic.as3.xmpp.IdHandler;
	import com.seesmic.as3.xmpp.IqStanza;
	import com.seesmic.as3.xmpp.PresenceStanza;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	import flash.utils.Dictionary;
	
	import org.swizframework.Swiz;
	
	public class XMPPModel
	{
		[Autowire(bean="appModel")]
		[Bindable]
		public var appModel:ApplicationModel;
		
		private function get settings():SettingsModel
		{
			return appModel.settings;
		}
			
		private function get database():DatabaseModel
		{
			return appModel.database;
		}
		
		private function get buddies():BuddyModel
		{
			return appModel.buddies;
		}
		
		private function get mBlogBuddies():MicroBloggingModel
		{
			return appModel.mBlogBuddies;
		}
		
		[Bindable]
		public var connected:Boolean = false;

		// flags to track progress during connecting
		private var gotAvatar:Boolean = false;
		private var gotRosterList:Boolean = false;

		// the xmpp object 
		private var xmpp:XMPP;
				
		//-------------------------------
		// CONSTRUCTOR
		//-------------------------------
		
		public function XMPPModel()
		{
			xmpp = new XMPP();
			
			// event listeners for starting session (this is the order in which
			// the events are dispatched
			xmpp.addEventListener(StreamEvent.CONNECTED, logHandler);
			xmpp.addEventListener(XMPPEvent.SECURE, logHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_SUCCEEDED, logHandler);
			xmpp.addEventListener(XMPPEvent.SESSION, sessionHandler);

			// fail handlers
			xmpp.addEventListener(StreamEvent.CONNECT_FAILED, failHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_FAILED, failHandler);
			xmpp.addEventListener(StreamEvent.DISCONNECTED, failHandler);

			// event listeners for messages, presance and changes to the roster
			xmpp.addEventListener(XMPPEvent.MESSAGE, messageHandler);
			xmpp.addEventListener(XMPPEvent.CHAT_STATE, chatStateHandler);
			xmpp.addEventListener(XMPPEvent.PRESENCE, presenceHandler);
			xmpp.addEventListener(XMPPEvent.ROSTER_ITEM, rosterListChangeHandler);
		}
		
		//-------------------------------
		// CONNECT
		//-------------------------------
		
		public function connect():void
		{
			if(connected || appModel.serverSideStatus.value == Status.CONNECTING)
				return;

			var account:UserAccount = settings.userAccount;
			if(account.jid && account.password)
			{
				gotAvatar = false;
				xmpp.auto_reconnect = true;
				appModel.serverSideStatus.value = Status.CONNECTING;

				xmpp.setJID(account.jid + "/cleartext");
				xmpp.setPassword(account.password);
				xmpp.setServer(account.server);
				xmpp.setupTLS(TLSEvent, TLSConfig, TLSEngine, TLSSocket, true, true, true);
				xmpp.connect();
			}
		}
		
		//-------------------------------
		// DISCONNECT
		//-------------------------------
		
		public function disconnect():void
		{
			if (connected)
			{
				connected = false;
		 		appModel.log("Disconnecting from XMPP server");
				xmpp.send("<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />");
		 		xmpp.disconnect();
		 	}
		 	
			xmpp.auto_reconnect = false;

		 	appModel.serverSideStatus.value = 
		 		(appModel.localStatus.value == Status.OFFLINE) ? 
		 		Status.OFFLINE : Status.ERROR;

	 		for each(var buddy:Buddy in buddies.buddies)
	 			buddy.status.value = Status.OFFLINE;
		}

		//-------------------------------
		// SESSION HANDLER
		//-------------------------------
		
		/**
		 * We have sucessfully initiated a session, now we can
		 * say the server knows our status and we can get the
		 * list of buddies and send our presence.
		 */
		private function sessionHandler(event:XMPPEvent):void
		{
			appModel.log(event);
			appModel.serverSideStatus.value = appModel.localStatus.value;
			connected = true;

			// get the roster list
			gotRosterList = false;
			sendIq(settings.userAccount.jid,
					IQTypes.GET,
					IQTypes.GET_ROSTER,
					getRosterHandler);

			// get the vCard stored on the server
			getVCard(settings.userAccount.jid);

			sendPresence();
		}
		
		//-------------------------------
		// LOG HANDLER
		//-------------------------------
		
		public function logHandler(event:Event):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// FAIL HANDLER
		//-------------------------------
		
		public function failHandler(event:Event):void
		{
			appModel.log(event);
			connected = false;
			disconnect();
		}

		//-------------------------------
		// MESSAGE HANDLER
		//-------------------------------
		
		/**
		 * receive a message stanza, find the associated sender and
		 * receiver buddies, save to the database and add to the correct
		 * chat or timeline
		 */
		private function messageHandler(event:XMPPEvent):void
		{
			var message:Message = Message.createFromStanza(event.stanza, mBlogBuddies);
			
			if(message.sender == "twitter.cleartext.com" && message.plainMessage == "The message has been sent")
				return;

			var buddy:Buddy = appModel.getBuddyByJid(message.sender);
			
			if(!buddy)
			{
				for each(var c:Chat in appModel.chats)
				{
					if(c.buddy.jid == message.sender)
					{
						buddy = chat.buddy;
						break;
					}
				}
			}

			if(!buddy)
			{
				buddy = new Buddy(message.sender);
				Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.BUDDY_NOT_IN_ROSTER_WINDOW, null, buddy));
			}
			
			buddy.lastSeen = message.timestamp;
			buddy.isTyping = false;
			buddy.resource = event.stanza.from.resource;
			buddy.unreadMessageCount++;

			var chat:Chat = appModel.getChat(buddy);
			chat.messages.addItemAt(message,0);
			
			if(buddy.microBlogging)
			{
				Buddy.ALL_MICRO_BLOGGING_BUDDY.unreadMessageCount++;
				chat = appModel.getChat(Buddy.ALL_MICRO_BLOGGING_BUDDY);
				chat.messages.addItemAt(message, 0);
			}

			database.saveMessage(message);
			database.saveBuddy(buddy);
		}
		
		private function chatStateHandler(event:XMPPEvent):void
		{
			var chatState:String = event.stanza.chatState;
			var fromJid:String = event.stanza.from.getBareJID();
			var buddy:Buddy = appModel.getBuddyByJid(fromJid);

			if(buddy)
				buddy.isTyping = (chatState == "composing");
		}
		
		//-------------------------------
		// PRESENCE HANDLER
		//-------------------------------
		
		private function presenceHandler(event:XMPPEvent):void
		{
			appModel.log(event);

			var stanza:PresenceStanza = event.stanza as PresenceStanza;
			var fromJid:String = stanza.from.getBareJID();
			var buddy:Buddy = appModel.getBuddyByJid(fromJid);
			
			if(fromJid == settings.userAccount.jid)
			{
				return;
			}

			// note this is just for type "subscribe" - "unsubscribed" and
			// "subscribed" are handled below
			else if(stanza.type == SubscriptionTypes.SUBSCRIBE)
			{
				if(!buddy)
					buddy = new Buddy(fromJid);
				Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.SUBSCRIPTION_REQUEST_WINDOW, null, buddy));
			}
			else
			{
				if(!buddy)
				{
					// we don't care about you if you aren't in our roster list
					return;
				}
				
				var wasOffline:Boolean = buddy.status.isOffline();
				
				buddy.resource = stanza.from.resource;
				// setFromStanzaType also handles "unsubscribe" and "subscribed"
				var error:Boolean = buddy.status.setFromStanzaType(stanza.type);
				buddy.customStatus = (!error) ? stanza.status : "";
				
				// only set last seen if the buddy was offline or we are now 
				// explicitly going online
				if(wasOffline || buddy.status.value == Status.AVAILABLE)
					buddy.lastSeen = new Date();
				
				var avatarHash:String = stanza.avatarHash;
				if(avatarHash && (buddy.avatarHash != avatarHash || !buddy.avatar))
				{
					buddy.tempAvatarHash = avatarHash;
					sendIq(buddy.jid, 'get', <vCard xmlns='vcard-temp'/>, vCardHandler);
				}
				
				buddies.buddies.refresh();
				database.saveBuddy(buddy);
			}
		}
		
		//-------------------------------
		// ROSTER CHANGED HANDLER
		//-------------------------------
		
		private function rosterListChangeHandler(event:XMPPEvent):void
		{
			if(connected && !gotRosterList)
				return;
			
			appModel.log("rosterListChangeHandler");
			
			var jid:String = event.stanza["jid"];

			// if we already have the buddy, then we just want to
			// update the values, otherwise create a new buddy
			var buddy:Buddy = appModel.getBuddyByJid(jid);
			if(!buddy)
				buddy = new Buddy(jid);

			var subscription:String = event.stanza["subscription"];
			if(subscription == SubscriptionTypes.REMOVE)
			{
				buddies.removeBuddy(buddy);
			}
			else
			{
				buddy.groups = event.stanza["groups"];
				buddy.nickName = event.stanza["name"];
				buddy.subscription = subscription;
				buddies.addBuddy(buddy);
			}
			buddies.refresh();
		}

		//-------------------------------
		// GET ROSTER HANDLER
		//-------------------------------
		
		private function getRosterHandler(stanza:IqStanza):void
		{
			appModel.log("getRosterHandler");
			
			var buddy:Buddy;
			var buddiesToDelete:Dictionary = new Dictionary();
			
			for each(buddy in buddies.buddies)
				buddiesToDelete[buddy.jid] = buddy;

			namespace rosterns = "jabber:iq:roster";
			for each(var item:XML in stanza.query.rosterns::item)
			{
				var jid:String = item.@jid;
				
				// if we already have the buddy, then we just want to
				// update the values, otherwise create a new buddy
				buddy = appModel.getBuddyByJid(jid);
				if(!buddy)
					buddy = new Buddy(jid);
				
				var groups:Array = new Array();
				for each(var group:XML in item.rosterns::group)
					{
						var gString:String = String(group.text());
						if(gString != "")
							groups.push(gString);
					}
				buddy.groups = groups;
				
				buddy.nickName = item.@name;
				buddy.subscription = item.@subscription;
				
				// flag used to delete buddies that are no longer in
				// the roster list
				delete buddiesToDelete[buddy.jid];
				
				// this adds, saves and adds an event listener to the buddy
				buddies.addBuddy(buddy);
			}
			
			for each(buddy in buddiesToDelete)
				buddies.removeBuddy(buddy);

			gotRosterList = true;
		}
		
		//-------------------------------
		// GET VCARD
		//-------------------------------
		
		private function getVCard(jid:String):void
		{
			sendIq(jid,
					IQTypes.GET,
					IQTypes.GET_USERS_VCARD,
					vCardHandler);	
		}
		
		//-------------------------------
		// VCARD HANDLER
		//-------------------------------
		
		private function vCardHandler(stanza:IqStanza):void
		{
			namespace vCardTemp = "vcard-temp";
			var xml:XML = stanza.getXML();
			
			var buddyJid:String = stanza.from;
			
			if(buddyJid == settings.userAccount.jid)
			{
				gotAvatar = true;
				var vCard:XMLList = xml.vCardTemp::vCard;
				var serverAvatar:String = vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				var localAvatar:String = AvatarUtils.avatarToString(settings.userAccount.avatar);
				
				// if we have a different avatar to the one on the server, then send a
				// vcard back to the server
				if(serverAvatar != localAvatar && localAvatar != "")
				{
					vCard.vCardTemp::PHOTO.vCardTemp::BINVAL = localAvatar;
					sendIq(settings.userAccount.jid, IQTypes.SET, vCard[0]);
				}
				
				// now we have the avatar, resend the presence to make sure the 
				// avatar hash is sent to our buddies
				sendPresence();
			}
			else
			{
				var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				var buddy:Buddy = appModel.getBuddyByJid(buddyJid);
				AvatarUtils.stringToAvatar(avatarString, buddy);
			}
		}
		
		//-------------------------------
		// SEND IQ
		//-------------------------------
		
		/**
		 * This function should really be in the seesmic library
		 */
		public function sendIq(tojid:String, type:String, payload:XML, responseHandler:Function=null):void
		{
			var iqStanza:IqStanza = new IqStanza(xmpp);
			var id:String = iqStanza.setID();

			if(responseHandler != null)
				xmpp.addHandler(new IdHandler(id, responseHandler));
			
			iqStanza.setTo(tojid);
			iqStanza.setType(type);
			iqStanza.setQuery(payload);
			iqStanza.send();
		}		
		
		//-------------------------------
		// SEND PRESENCE
		//-------------------------------
		
		public function sendPresence():void
		{
			var status:Status = appModel.localStatus;
			var customStatus:String = settings.userAccount.customStatus;

			// if we are connected and want to go offline, then disconnect
			if(connected && status.value == Status.OFFLINE)
			{
				disconnect();
			}
			
			// if we are already connected, then send the presence
			else if(connected)
			{
				var priority:String = (status.value == Status.AWAY || status.value == Status.EXTENDED_AWAY) ? "0" : "5";
				xmpp.sendPresence(customStatus, status.toShow(), priority, "", (gotAvatar) ? settings.userAccount.avatarHash : "");
				appModel.serverSideStatus.value = status.value;
			}
			
			// if we want to connect, then try to connect, if we are successful, then
			// we will send the presence once the session is established
			else if(status.value != Status.OFFLINE)
			{
				connect();
			}	
		}
		
		//-------------------------------
		// SEND MESSAGE
		//-------------------------------
		
		public function sendMessage(toJid:String, body:String, subject:String=null, type:String='chat', chatState:String=null):void
		{
			xmpp.sendMessage(toJid, body, subject, type, chatState);
		}
		
		//-------------------------------
		// ADD TO ROSTER 
		//-------------------------------
		
		public function addToRoster(toJid:String, nickName:String, groups:Array, newSubscription:String):void
		{
			sendIq(settings.userAccount.jid,
					IQTypes.SET,
					IQTypes.addRemoveRosterItem(toJid, nickName, groups, false),
					modifyRosterHandler);

			if(newSubscription)
				sendSubscribe(toJid, newSubscription);
		}
		
		//-------------------------------
		// REMOVE FROM ROSTER
		//-------------------------------
		
		public function removeFromRoster(toJid:String, newSubscription:String):void
		{
			if(newSubscription)
				sendSubscribe(toJid, newSubscription);

			sendIq(settings.userAccount.jid, 
					IQTypes.SET,
					IQTypes.addRemoveRosterItem(toJid, null, null, true),
					modifyRosterHandler);
		}

		//-------------------------------
		// MODIFY ROSTER HANDLER
		//-------------------------------
		
		public function modifyRosterItem(buddy:Buddy):void
		{
			sendIq(settings.userAccount.jid,
					IQTypes.SET,
					IQTypes.modifyRosterItem(buddy),
					modifyRosterHandler);
		}
		
		//-------------------------------
		// MODIFY ROSTER HANDLER
		//-------------------------------
		
		private function modifyRosterHandler(stanza:IqStanza):void
		{
			/**
			 * TO DO:
			 */
			buddies.refresh();
			appModel.log("modifyRosterHandler");
		}

		//-------------------------------
		// SEND SUBSCRIBE
		//-------------------------------
		
		public function sendSubscribe(toJid:String, type:String):void
		{
			xmpp.send('<presence to="' + toJid + '" type="' + type + '" />');
		}
		
		public function getAvatarForMBlogBuddy(jid:String):void
		{
			sendIq(jid, 'get', <vCard xmlns='vcard-temp'/>, mBlogVCardHandler);
		}
		
		private function mBlogVCardHandler(stanza:IqStanza):void
		{
			namespace vCardTemp = "vcard-temp";
			var xml:XML = stanza.getXML();
			
			var buddyJid:String = stanza.from;
			
			var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
			var buddy:MicroBloggingBuddy = mBlogBuddies.getBuddyByJid(buddyJid);
			AvatarUtils.stringToAvatar(avatarString, buddy);
		}
	}
}