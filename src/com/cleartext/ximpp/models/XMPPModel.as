package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	import com.hurlant.crypto.tls.TLSConfig;
	import com.hurlant.crypto.tls.TLSEngine;
	import com.hurlant.crypto.tls.TLSEvent;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.seesmic.as3.xmpp.JID;
	import com.seesmic.as3.xmpp.Stanza;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	import com.seesmic.as3.xmpp.XPathHandler;
	
	import flash.events.Event;
	
	public class XMPPModel
	{
		private var xmpp:XMPP = new XMPP();
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;
		
		private var firstTime:Boolean = false;
		
		private function get settings():SettingsModel
		{
			return appModel.settings;
		}
			
		private function get database():DatabaseModel
		{
			return appModel.database;
		}
				
		public var connected:Boolean = false;
		
		public function XMPPModel()
		{
			// set up event listeners
			xmpp.addEventListener(XMPPEvent.MESSAGE, messageHandler);
			xmpp.addEventListener(XMPPEvent.SESSION, sessionHandler);
			xmpp.addEventListener(XMPPEvent.SECURE, secureHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_SUCCEEDED, authSucceededHandler);
			xmpp.addEventListener(XMPPEvent.AUTH_FAILED, authFailedHandler);
			xmpp.addEventListener(XMPPEvent.PRESENCE, presenceHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_UNAVAILABLE, presenceUnavailableHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_ERROR, presenceErrorHandler);
//			xmpp.addEventListener(XMPPEvent.PRESENCE_SUBSCRIBE, presenceSubscribeHandler);
			xmpp.addEventListener(XMPPEvent.ROSTER_LIST_CHANGE, rosterListChangeHandler);

			xmpp.addHandler(new XPathHandler("{jabber:client}iq/{vcard-temp}vCard", vCardHandler));			
		}
		
		
		//-------------------------------
		// VCARD HANDLER
		//-------------------------------
		
		private function vCardHandler(stanza:Stanza):void
		{
			namespace vCardTemp = "vcard-temp";
			var xml:XML = stanza.getXML();
			
			var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
			var buddyJid:String = xml.@from;
			
			var buddy:Buddy = appModel.getBuddyByJid(buddyJid);
			XimppUtils.stringToAvatar(avatarString, buddy);
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
			var message:Message = Message.createFromStanza(event.stanza);
			database.saveMessage(message);

			var buddy:Buddy = appModel.getBuddyByJid(message.sender);
			if(!buddy)
			{
				buddy = new Buddy();
				buddy.jid = message.sender;
				appModel.addBuddy(buddy);
			}
			
			buddy.lastSeen = message.timestamp;
			buddy.resource = event.stanza.from.resource;
			
			database.saveBuddy(buddy);
			
			var chat:Chat = appModel.getChat(buddy);
			chat.messages.addItem(message);
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
			connected = true;
			appModel.log(event);
			appModel.serverSideStatus = appModel.localStatus;
			firstTime = true;
			xmpp.getRoster();
			sendPresence();
		}
		
		//-------------------------------
		// SECURE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function secureHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// AUTH SUCCEDED HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function authSucceededHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// AUTH FAILED HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function authFailedHandler(event:XMPPEvent):void
		{
			connected = false;
			errorHandler(event);
		}
		
		//-------------------------------
		// PRESENCE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function presenceHandler(event:XMPPEvent):void
		{
			var stanza:Stanza = event.stanza as Stanza;
			
			var fromJid:JID = stanza["from"];
			var buddy:Buddy = appModel.getBuddyByJid(fromJid.getBareJID());
			
			if(!buddy || buddy.jid == settings.userAccount.jid)
				return;
			
			buddy.resource = fromJid.resource;
			buddy.status.setFromShow((stanza["type"]));
			buddy.customStatus = stanza["status"];
			
			namespace vcard = "vcard-temp:x:update";
			var xml:XML = stanza.getXML();
			var avatarHash:String = xml.vcard::x.vcard::photo;
			
			if(avatarHash && buddy.avatarHash != avatarHash)
			{
				buddy.tempAvatarHash = avatarHash;
				xmpp.send("<iq from='" + settings.userAccount.jid + "' to='" + buddy.jid + "' type='get' id='vc2'><vCard xmlns='vcard-temp'/></iq>");
			}

			database.saveBuddy(buddy);
			appModel.log(event);
		}
		
		//-------------------------------
		// PRESENCE UNAVILABLE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function presenceUnavailableHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// PRESENCE ERROR HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function presenceErrorHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// PRESENCE SUBSCRIBE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function presenceSubscribeHandler(event:XMPPEvent):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// ROSTER COMPLETE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function rosterListChangeHandler(event:XMPPEvent):void
		{
			if(firstTime)
			{
				for each(var b1:Buddy in appModel.buddyByJid)
					b1.used = false;
			}
			
			for each(var item:Object in event.stanza)
			{
				var jid:String = item["jid"];
				
				var existingBuddy:Buddy = appModel.getBuddyByJid(jid);
				if(existingBuddy)
				{
					existingBuddy.used = true;
					existingBuddy.groups = item["groups"];
					database.saveBuddy(existingBuddy);
				}
				else
				{
					var newBuddy:Buddy = new Buddy();
					newBuddy.jid = jid;
					newBuddy.groups = item["groups"];
					appModel.addBuddy(newBuddy);
				}
			}
			
			if(firstTime)
			{
				firstTime = false;
				for each(var b2:Buddy in appModel.buddyByJid)
					if(!b2.used)
						appModel.removeBuddy(b2);
			}
		}
		
		//-------------------------------
		// CONNECT
		//-------------------------------
		
		/**
		 * ...
		 */
		public function connect():void
		{
			if(connected)
				return;

			var account:UserAccount = settings.userAccount;
			if(account.jid && account.password)
			{
				xmpp.auto_reconnect = true;
				appModel.serverSideStatus.value = Status.CONNECTING;

				xmpp.setJID(account.jid);
				xmpp.setPassword(account.password);
				xmpp.setServer(account.server);
				
				xmpp.socket.addEventListener(StreamEvent.DISCONNECTED, streamDisconnectedHandler);
				xmpp.socket.addEventListener(StreamEvent.CONNECT_FAILED, streamConnectFailedHandler);
				xmpp.socket.addEventListener(StreamEvent.CONNECTED, streamConnectedHandler);
				
				// do the tls bit now
				xmpp.setupTLS(TLSEvent, TLSConfig, TLSEngine, TLSSocket, true, true, true);
				xmpp.connect();
			}
		}
		
		//-------------------------------
		// DISCONNECT
		//-------------------------------
		
		/**
		 * ...
		 */
		public function disconnect():void
		{
			if (connected)
			{
				xmpp.auto_reconnect = false;
				connected = false;
		 		appModel.log("Disconnecting from XMPP server");
		 		var presenceType:String = "<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />";
				xmpp.send(presenceType);
		 		xmpp.disconnect();
		 		appModel.serverSideStatus.value = Status.OFFLINE;
		 		for each(var buddy:Buddy in appModel.buddyCollection)
		 		{
		 			buddy.status.value = Status.OFFLINE;
		 		}
		 	}
		}
		
		//-------------------------------
		// STREAM DISCONNECTED HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function streamDisconnectedHandler(event:StreamEvent):void
		{
			connected = false;
			appModel.log(event);
		}

		//-------------------------------
		// STREAM CONNECT FAILED HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function streamConnectFailedHandler(event:StreamEvent):void
		{
			connected = false;
			errorHandler(event);
		}

		//-------------------------------
		// STREAM CONNECTED HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function streamConnectedHandler(event:StreamEvent):void
		{
			appModel.log(event);	
		}

		//-------------------------------
		// SEND PRESENCE
		//-------------------------------
		
		/**
		 * ...
		 */
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
				xmpp.sendPresence(customStatus, status.toShow(), "5");
				appModel.serverSideStatus = status;
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
		
		/**
		 * ...
		 */
		public function sendMessage(toJid:String, msg:String):void
		{
			if(connected)
				xmpp.sendMessage(toJid, msg);
		}

		//-------------------------------
		// ERROR HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		public function errorHandler(event:Event):void
		{
			appModel.log(event);
			disconnect();
			appModel.serverSideStatus.value = Status.ERROR;
		}

	}
}