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
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	public class XMPPModel
	{
		private var xmpp:XMPP = new XMPP();
		
		[Autowire]
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
				
		public function get connected():Boolean
		{
			return xmpp.state["connected"];
		}
		
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
			xmpp.addEventListener(XMPPEvent.ROSTER_COMPLETE, rosterCompleteHandler);
			xmpp.auto_reconnect = true;
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
			buddy.lastSeen = message.timestamp;
			buddy.resource = event.stanza.from.resource;
			
			database.saveBuddy(buddy);
			
			var chat:Chat = appModel.getChat(buddy);
			chat.messages.addItem(message);

			appModel.log("message:  " + message.body);
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
			appModel.serverSideStatus = appModel.localStatus;
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
			appModel.log(event);
		}
		
		//-------------------------------
		// PRESENCE HANDLER
		//-------------------------------
		
		/**
		 * ...
		 */
		private function presenceHandler(event:XMPPEvent):void
		{
			var stanza:Object = event.stanza;
			
			var fromJid:JID = stanza["from"];
			var buddy:Buddy = appModel.getBuddyByJid(fromJid.getBareJID());
			
			if(!buddy || buddy.jid == settings.userAccount.jid)
				return;
			
			buddy.resource = fromJid.resource;
			buddy.status.setFromShow((stanza["type"]));
			buddy.customStatus = stanza["status"];
			
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
		private function rosterCompleteHandler(event:XMPPEvent):void
		{
			for each(var b1:Buddy in appModel.buddyByJid)
			{
				b1.used = false;
			}
			
			for each(var item:Object in event.stanza)
			{
				var buddy:Buddy = Buddy.createFromStanza(item);
				appModel.addBuddy(buddy);
			}
			
			for each(var b2:Buddy in appModel.buddyByJid)
			{
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
			disconnect();
			
			appModel.serverSideStatus.value = Status.CONNECTING;

			var account:UserAccount = settings.userAccount;
			if(account.jid &&
				account.password)
			{
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
		 		appModel.log("Disconnecting from XMPP server");
		 		var presenceType:String = "<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />";
				xmpp.send(presenceType);
		 		xmpp.disconnect();
		 		appModel.serverSideStatus.value = Status.OFFLINE;
		 		for each(var buddy:Buddy in appModel.buddyCollection)
		 		{
		 			buddy.status.value = Status.OFFLINE;
		 			buddy.customStatus = "";
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
			appModel.log(event);
			appModel.serverSideStatus.value = Status.OFFLINE;
			if(!settings.global.autoConnect)
				appModel.localStatus.value = Status.OFFLINE;
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

	}
}