package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.ApplicationEvent;
	import com.cleartext.ximpp.events.UserAccountEvent;
	import com.cleartext.ximpp.models.types.ChatStateTypes;
	import com.cleartext.ximpp.models.types.IQTypes;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
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
	import com.seesmic.as3.xmpp.MessageStanza;
	import com.seesmic.as3.xmpp.PresenceStanza;
	import com.seesmic.as3.xmpp.StreamEvent;
	import com.seesmic.as3.xmpp.XMPP;
	import com.seesmic.as3.xmpp.XMPPEvent;
	
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import org.swizframework.Swiz;
	
	public class XMPPModel
	{
		//------------------------------------------------------------------
		//
		//   NAMESPACES
		//
		//------------------------------------------------------------------
		
		namespace discoInfo = "http://jabber.org/protocol/disco#info";
		public var DISCO_INFO_NS:String = "http://jabber.org/protocol/disco#info";
		
		namespace discoItems = "http://jabber.org/protocol/disco#items";
		public var DISCO_ITEMS_NS:String = "http://jabber.org/protocol/disco#items";

		namespace jabberRegister = "jabber:iq:register";
		public var JABBER_REGISTER_NS:String = "jabber:iq:register";

		namespace muc = "http://jabber.org/protocol/muc";
		public var MUC_NS:String = "http://jabber.org/protocol/muc";

		namespace vCardTemp = "vcard-temp";
		public var V_CARD_TEMP_NS:String = "vcard-temp";
		
		namespace jabberRoster = "jabber:iq:roster";
		public var JABBER_ROSTER_NS:String = "jabber:iq:roster";

		//------------------------------------------------------------------
		//
		//   MODELS
		//
		//------------------------------------------------------------------
		
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
		
		private function get requests():BuddyRequestModel
		{
			return appModel.requests;
		}
		
		private function get chats():ChatModel
		{
			return appModel.chats;
		}
		
		private function get soundColor():SoundAndColorModel
		{
			return appModel.soundColor;
		}
		
		//------------------------------------------------------------------
		//
		//   VARIABLES
		//
		//------------------------------------------------------------------
		
		[Bindable]
		public var connected:Boolean = false;

		// a dictionary to store the nicknames that we have used to 
		// log into various chat rooms the key of the dictonary is the 
		// jid of the chat room
		private var chatRoomNicknames:Dictionary = new Dictionary();
		
		// a dictionary to store the variables that we want to associate
		// with iq queries the key is the id of the iq stanza the we
		// are sending out
		private var iqVariables:Dictionary = new Dictionary();
		
		// flags to track progress during connecting
		private var gotAvatar:Boolean = false;
		private var gotRosterList:Boolean = false;

		// the seesmic xmpp object 
		private var xmpp:XMPP;
				
		//------------------------------------------------------------------
		//
		//   CONSTRUCTOR
		//
		//------------------------------------------------------------------
		
		public function XMPPModel()
		{
			xmpp = new XMPP();
			
			// stream event listeners 
			xmpp.addEventListener(StreamEvent.COMM_IN, consoleHandler);
			xmpp.addEventListener(StreamEvent.COMM_OUT, consoleHandler);
			
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
			xmpp.addEventListener(XMPPEvent.MESSAGE_MUC, messageHandler);
		}
		
		//------------------------------------------------------------------
		//
		//   CONNECTION / DISCONNECTION HANDLERS
		//
		//------------------------------------------------------------------
		
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

				xmpp.setJID(account.jid);
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
		 		appModel.log("Disconnecting from XMPP server");
				xmpp.send("<presence from='" + xmpp.fulljid.toString() + "' type='unavailable' status='Logged out' />");
				connected = false;
		 	}
		 	
	 		xmpp.disconnect();
			xmpp.auto_reconnect = false;

		 	appModel.serverSideStatus.value = 
		 		(appModel.localStatus.value == Status.OFFLINE) ? 
		 		Status.OFFLINE : Status.ERROR;

	 		for each(var buddy:Buddy in buddies.buddies.source)
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
					<query xmlns={JABBER_ROSTER_NS}/>,
					getRosterHandler);

			// get the vCard stored on the server
			getVCard(settings.userAccount.jid);

			sendPresence();
		}
		
		//------------------------------------------------------------------
		//
		//   LOG / CONSOLE / FAIL HANDLERS
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// LOG HANDLER
		//-------------------------------
		
		public function logHandler(event:Event):void
		{
			appModel.log(event);
		}
		
		//-------------------------------
		// CONSOLE HANDLER
		//-------------------------------
		
		public function consoleHandler(event:StreamEvent):void
		{
			appModel.xmlStreamHandler(event);
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

		//------------------------------------------------------------------
		//
		//   MESSAGE / CHATSTATE HANDLER
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// MESSAGE HANDLER
		//-------------------------------
		
		/**
		 * receive a message stanza, find the associated sender and
		 * receiver buddies, save to the database and add to the correct
		 * chat
		 */
		private function messageHandler(event:XMPPEvent):void
		{
			var messageStanza:MessageStanza = event.stanza as MessageStanza;
			
			// ignore "The message has been sent." messages
			if(messageStanza.body == "The message has been sent.")
				return;
			
			var message:Message = appModel.createFromStanza(messageStanza);
			var buddy:Buddy = appModel.getBuddyByJid(message.sender);
			
			// if the buddy does not exist in our buddy list, then treat it as a buddy
			// request
			if(!buddy)
			{
				requests.receiving(message.sender, messageStanza.nick, message.plainMessage);
				database.saveMessage(message);
				return;
			}
			
			buddy.lastSeen = message.receivedTimestamp;
			buddy.isTyping = false;

			// if this is a message from a groupchat, then work out the 
			// sender's nickname
			if(buddy.isChatRoom)
			{
				message.groupChatSender = event.stanza.from.resource;
			}
			// otherwise set the buddy's resource, we only save the message
			// if it isn't from a chatRoom
			else
			{
				buddy.resource = event.stanza.from.resource;
				database.saveMessage(message);
			}

			buddy.unreadMessages++;
			
			chats.addMessage(buddy, message);
			
			// play sounds & increment unread messages for the mblog buddy
			if(buddy.isMicroBlogging)
			{
				soundColor.play(SoundAndColorModel.NEW_SOCIAL);
				Buddy.ALL_MICRO_BLOGGING_BUDDY.unreadMessages++;
			}
			else
			{
				soundColor.play(SoundAndColorModel.NEW_MESSAGE);
			}
				
			// notify the user (bounce the dock icon etc.)
			Swiz.dispatchEvent(new ApplicationEvent(ApplicationEvent.NOTIFY));
		}
		
		//-------------------------------
		// CHAT STATE HANDLER
		//-------------------------------
		
		private function chatStateHandler(event:XMPPEvent):void
		{
			var chatState:String = event.stanza.chatState;
			var fromJid:String = event.stanza.from.getBareJID();
			var buddy:Buddy = appModel.getBuddyByJid(fromJid);

			if(buddy)
				buddy.isTyping = (chatState == ChatStateTypes.COMPOSING);
		}
		
		//------------------------------------------------------------------
		//
		//   PRESENCE HANDLER
		//
		//------------------------------------------------------------------
		
		private function presenceHandler(event:XMPPEvent):void
		{
			appModel.log(event);

			var stanza:PresenceStanza = event.stanza as PresenceStanza;
			var fromJid:String = stanza.from.getBareJID();
			var buddy:Buddy = appModel.getBuddyByJid(fromJid);
			
			// if this is our own presence we don't care
			if(fromJid == settings.userAccount.jid)
				return;
			
			// if this is from a chat room that we have asked to join
			if(chatRoomNicknames.hasOwnProperty(fromJid))
			{
				// if the resource of the jid is equal to the nickname that 
				// we requested for this room, then open the chat, or show
				// an error on unavailable
				if(stanza.from.resource == chatRoomNicknames[fromJid])
				{
					if(stanza.type == Status.AVAILABLE)
						chats.getChat(fromJid, true, Buddy.CHAT_ROOM);
					else if(stanza.type == Status.UNAVAILABLE)
						chats.getChat(fromJid, false, Buddy.CHAT_ROOM).buddy.status.value = Status.ERROR;
				}
				
				return;
			}

			// if this is a subscription request
			if(stanza.type == SubscriptionTypes.SUBSCRIBE)
			{
				// if there are in our rosterlist, then auto-subscirbe
				if(buddy)
				{
					sendSubscribe(buddy.jid, SubscriptionTypes.SUBSCRIBED);
					if(!buddy.subscribedTo)
						sendSubscribe(buddy.jid, SubscriptionTypes.SUBSCRIBE);
				}
				// if they aren't in the roster list, then alert the user
				else
				{
					requests.receiving(fromJid, stanza.nick);
					// notify the user - bounce the dock icon etc
					Swiz.dispatchEvent(new ApplicationEvent(ApplicationEvent.NOTIFY));
				}
			}
			// all other presence types (including subscribed and unsubscribed can
			// be handled here - using Status.setFromStanzaType()
			else
			{
				if(!buddy)
				{
					// we don't care about you if you aren't in our roster list
					return;
				}
				
				var wasOffline:Boolean = buddy.status.isOffline();
				
				buddy.resource = stanza.from.resource;
				// setFromStanzaType also handles "unsubscribed" and "subscribed"
				// if there is an error, then reset the customStatus, otherwise
				// set the customStatus from the stanza
				var error:Boolean = buddy.status.setFromStanzaType(stanza.type);
				buddy.customStatus = (error) ? "" : stanza.status;
				
				// only set lastSeen if the buddy was offline or we are now 
				// explicitly going online
				if(wasOffline || buddy.status.value == Status.AVAILABLE)
				{
					buddy.lastSeen = new Date();
					doDiscovery(buddy.fullJid);
				}
				
				var avatarHash:String = stanza.avatarHash;
				if(avatarHash && (buddy.avatarHash != avatarHash || !buddy.avatar))
				{
					buddy.tempAvatarHash = avatarHash;
					getVCard(buddy.jid);
				}
				
				buddies.buddies.refresh();
				database.saveBuddy(buddy);
			}
		}
		
		//------------------------------------------------------------------
		//
		//   ROSTER HANDLERS
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// GET ROSTER HANDLER - CALLED TO GET INITAL ROSTER LIST AFTER CONNECTION
		//-------------------------------
		
		private function getRosterHandler(stanza:IqStanza):void
		{
			appModel.log("getRosterHandler");
			
			var buddy:Buddy;
			var buddiesToDelete:Dictionary = new Dictionary();
			
			for each(buddy in buddies.buddies.source)
				buddiesToDelete[buddy.jid] = buddy;

			for each(var item:XML in stanza.query.jabberRoster::item)
			{
				var jid:String = item.@jid;
				
				// if we already have the buddy, then we just want to
				// update the values, otherwise create a new buddy
				buddy = appModel.getBuddyByJid(jid);
				if(!buddy)
					buddy = new Buddy(jid);
				
				var groups:Array = new Array();
				for each(var group:XML in item.jabberRoster::group)
					{
						var gString:String = String(group.text());
						if(gString != "")
							groups.push(gString);
					}
				buddy.groups = groups;
				
				buddy.nickName = item.@name;
				buddy.subscription = item.@subscription;
				requests.setSubscription(jid, buddy.nickName, buddy.subscription);

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
		// ROSTER CHANGED HANDLER - CALLED WHENEVER THE ROSTER LIST CHANGES AFTER CONNECTION
		//-------------------------------
		
		private function rosterListChangeHandler(event:XMPPEvent):void
		{
			// if we haven't already got the roster list, then ignore
			if(connected && !gotRosterList)
				return;
			
			appModel.log("rosterListChangeHandler");
			
			var jid:String = event.stanza["jid"];

			// if we already have the buddy, then we just want to
			// update the values, otherwise create a new buddy
			var buddy:Buddy = appModel.getBuddyByJid(jid);
			if(!buddy)
			{
				buddy = new Buddy(jid);
				buddies.addBuddy(buddy);
			}

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
				
				requests.setSubscription(jid, buddy.nickName, buddy.subscription);
			}
			buddies.refresh();
		}

		//-------------------------------
		// ADD TO ROSTER 
		//-------------------------------
		
		public function addToRoster(toJid:String, nickName:String, groups:Array):void
		{
			var query:XML = <query xmlns={JABBER_ROSTER_NS} />;
			var item:XML = <item jid={toJid} />;
			if(nickName)
				item.@name = nickName;
			
			for each(var group:String in groups)
				item.appendChild(<group>{group}</group>);
			
			query.appendChild(item);

			sendIq(settings.userAccount.jid,
					IQTypes.SET,
					query,
					addToRosterHandler,
					toJid);
		}

		//-------------------------------
		// ADD TO ROSTER HANDLER
		//-------------------------------
		
		private function addToRosterHandler(stanza:IqStanza):void
		{
			var id:String = stanza.id;
			if(iqVariables.hasOwnProperty(id))
			{
				var toJid:String = iqVariables[id] as String;
				sendSubscribe(toJid, SubscriptionTypes.SUBSCRIBE);
				chats.getChat(appModel.getBuddyByJid(toJid), true);
				delete iqVariables[id];
			}
			appModel.log("addToRosterHandler");
		}

		//-------------------------------
		// REMOVE FROM ROSTER
		//-------------------------------
		
		public function removeFromRoster(toJid:String):void
		{
			chats.removeChat(toJid);
			sendIq(settings.userAccount.jid, 
					IQTypes.SET,
					<query xmlns={JABBER_ROSTER_NS}><item jid={toJid} subscription={SubscriptionTypes.REMOVE} /></query>,
					removeFromRosterHandler);
		}

		//-------------------------------
		// REMOVE FROM ROSTER HANDLER
		//-------------------------------
		
		private function removeFromRosterHandler(stanza:IqStanza):void
		{
			appModel.log("removeFromRosterHandler");
		}

		//-------------------------------
		// MODIFY ROSTER ITEM
		//-------------------------------
		
		public function modifyRosterItem(buddy:Buddy):void
		{
			var query:XML = <query xmlns={JABBER_ROSTER_NS} />;
			var item:XML = <item jid={buddy.jid} subscription={buddy.subscription} />;
			if(buddy.nickName != buddy.jid)
				item.@name = buddy.nickName;
			
			for each(var group:String in buddy.groups)
				item.appendChild(<group>{group}</group>);
			
			query.appendChild(item);
			
			sendIq(settings.userAccount.jid,
					IQTypes.SET,
					query,
					modifyRosterHandler);
		}
		
		//-------------------------------
		// MODIFY ROSTER HANDLER
		//-------------------------------
		
		private function modifyRosterHandler(stanza:IqStanza):void
		{
			appModel.log("modifyRosterHandler");
		}

		//------------------------------------------------------------------
		//
		//   VCARD HANDLERS
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// GET VCARD
		//-------------------------------
		
		private function getVCard(jid:String):void
		{
			sendIq(jid,
					IQTypes.GET,
					<vCard xmlns='vcard-temp'/>,
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
			
			// if we are downloading our v-card from the server
			if(buddyJid == settings.userAccount.jid)
			{
				gotAvatar = true;
				var vCard:XMLList = xml.vCardTemp::vCard;
				var serverAvatar:String = vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				var localAvatar:String = settings.userAccount.avatarString;
				
				// if we have a different avatar to the one on the server, then send a
				// vcard back to the server
				if(serverAvatar != localAvatar && localAvatar != "" && localAvatar != "null")
				{
					vCard.vCardTemp::PHOTO.vCardTemp::BINVAL = localAvatar;
					sendIq(settings.userAccount.jid, IQTypes.SET, vCard[0]);
				}
				else if(localAvatar == "" || localAvatar == "null")
				{
					settings.userAccount.avatarString = serverAvatar;
				}

				// now we have the avatar, resend the presence to make sure the 
				// avatar hash is sent to our buddies
				sendPresence();
			}
			else
			{
				var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				var buddy:Buddy = appModel.getBuddyByJid(buddyJid);
				buddy.avatarString = avatarString;
			}
		}
		
		//-------------------------------
		// GET VCARD AVATAR FOR MBLOG BUDDY
		//-------------------------------
		
		public function getAvatarForMBlogBuddy(jid:String):void
		{
			sendIq(jid, 
				IQTypes.GET, 
				<vCard xmlns='vcard-temp'/>, 
				mBlogVCardHandler);
		}
		
		//-------------------------------
		// MBLOG BUDDY VCARD HANDLER
		//-------------------------------
		
		private function mBlogVCardHandler(stanza:IqStanza):void
		{
			var xml:XML = stanza.getXML();
			var buddyJid:String = stanza.from;
			var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
			var buddy:MicroBloggingBuddy = mBlogBuddies.getBuddyByJid(buddyJid);
			buddy.avatarString = avatarString;
		}
		
		//------------------------------------------------------------------
		//
		//   SEND IQ / PRESENCE / MESSAGE
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// SEND IQ
		//-------------------------------
		
		public function sendIq(tojid:String, type:String, payload:XML, responseHandler:Function=null, responseVariables:Object=null):void
		{
			var iqStanza:IqStanza = new IqStanza(xmpp);
			var id:String = iqStanza.setID();

			if(responseHandler != null)
				xmpp.addHandler(new IdHandler(id, responseHandler));
			
			if(responseVariables != null)
				iqVariables[id] = responseVariables;
			
			iqStanza.setTo(tojid);
			iqStanza.setType(type);
			iqStanza.setQuery(payload);
			iqStanza.send();
		}
		
		//-------------------------------
		// SEND PRESENCE
		//-------------------------------
		
		public function sendPresence(toJid:String=""):void
		{
			var status:Status = appModel.localStatus;
			var customStatus:String = settings.userAccount.customStatus;

			// if we want to go offline, then disconnect
			if(status.value == Status.OFFLINE)
			{
				disconnect();
			}
			
			// if we are already connected, then send the presence
			else if(connected)
			{
				var priority:String = (status.value == Status.AWAY || status.value == Status.EXTENDED_AWAY) ? "0" : "5";
				xmpp.sendPresence(customStatus, status.toShow(), priority, toJid, (gotAvatar) ? settings.userAccount.avatarHash : "");
				appModel.serverSideStatus.value = status.value;
			}
			
			// if we want to connect, then try to connect, if we are successful, then
			// we will send the presence once the session is established
			else
			{
				connect();
			}	
		}
		
		//-------------------------------
		// SEND MESSAGE
		//-------------------------------
		
		public function sendMessage(toJid:String, body:String, subject:String=null, type:String='chat', chatState:String=null, customTags:Array=null):MessageStanza
		{
			return xmpp.sendMessage(toJid, body, subject, type, chatState, customTags);
		}
		
		//------------------------------------------------------------------
		//
		//   SEND SUBSCRIBE / BLOCK
		//
		//------------------------------------------------------------------
		
		public function sendSubscribe(toJid:String, type:String):void
		{
			if(type == SubscriptionTypes.SUBSCRIBE)
				requests.sending(toJid);

			xmpp.send('<presence to="' + toJid + '" type="' + type + '" />');
		}
		
		//-------------------------------
		// SEND BLOCK - TODO
		//-------------------------------
		
		public function sendBlock(toJid:String):void
		{
//			// get the blocked list
//			sendIq(settings.userAccount.jid,
//				IQTypes.GET,
//			
//			sendIq(settings.userAccount.jid,
//				IQTypes.SET,
//				new XML("<query xmln='jabber:iq:privacy'><list name='blocked'><item type='jid' value ='" + toJid + "' action='deny' order"));
		}
		
		//------------------------------------------------------------------
		//
		//   SEND XML STRING
		//
		//------------------------------------------------------------------
		
		public function sendXmlString(xmlString:String):void
		{
			xmpp.send(xmlString);
		}
		
		//------------------------------------------------------------------
		//
		//   JOIN / LEAVE CHAT ROOM
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// JOIN CHAT ROOM
		//-------------------------------
		
		public function joinChatRoom(roomJid:String, nickname:String, password:String=""):void
		{
			chatRoomNicknames[roomJid] = nickname;
			xmpp.send('<presence to="' + roomJid + "/" + nickname + '">' + (password=="" ? '' : '<password>' + password + '</password>') + "<x xmlns='" + MUC_NS + "'/></presence>");
		}
		
		//-------------------------------
		// LEAVE CHAT ROOM
		//-------------------------------
		
		public function leaveChatRoom(roomJid:String):void
		{
			delete chatRoomNicknames[roomJid];
			xmpp.send('<presence type="unavailable" to="' + roomJid + "/" + chatRoomNicknames[roomJid] +'" />');
		}
		
		//------------------------------------------------------------------
		//
		//   PASSWORD
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// CHANGE PASSWORD
		//-------------------------------
		
		public function changePassword(newPassword:String):void
		{
			sendIq(xmpp.fulljid.host,
				IQTypes.SET, 
				<query xmlns={JABBER_REGISTER_NS}><username>{xmpp.fulljid.user}</username><password>{newPassword}</password></query>,
				changePasswordHandler);
		}
		
		//-------------------------------
		// CHANGE PASSWORD HANDLER
		//-------------------------------
		
		public function changePasswordHandler(stanza:IqStanza):void
		{
			Alert.show("Password successfully changed", "Change Password");
			var xml:XML = stanza.getXML();
			var newPassword:String = xml.jabberRegister::query.jabberRegister::password.text();
			settings.userAccount.password = newPassword;
			Swiz.dispatchEvent(new UserAccountEvent(UserAccountEvent.PASSWORD_CHANGE, null, newPassword));
		}
		
		//------------------------------------------------------------------
		//
		//   DISCOVERY
		//
		//------------------------------------------------------------------
		
		public function doDiscovery(toJid:String):void
		{
			discoveryInfo(toJid);
			discoveryItems(toJid);
		}

		//-------------------------------
		// DISCOVERY INFO
		//-------------------------------

		public function discoveryInfo(toJid:String):void
		{
			sendIq(toJid,
					IQTypes.GET,
					<query xmlns={DISCO_INFO_NS}/>,
					discoveryInfoHandler);
		}
		
		//-------------------------------
		// DISCOVERY INFO HANDLER
		//-------------------------------

		public function discoveryInfoHandler(iqStanza:IqStanza):void
		{
			var fromJid:String = iqStanza.from;
			var bareJid:String = (fromJid.indexOf("/") == -1) ? fromJid : fromJid.substr(0, fromJid.indexOf("/"));
			var buddy:Buddy = appModel.getBuddyByJid(bareJid);
			if(!buddy)
				return;
			
			if(iqStanza.query)
			{
				for each(var feature:XML in iqStanza.query.discoInfo::feature)
				{
					var ns:String = feature.attribute("var").toString();
					buddy.features.push(ns);
				}
			}
		}
		
		//-------------------------------
		// DISCOVERY ITEMS
		//-------------------------------

		public function discoveryItems(toJid:String):void
		{
			sendIq(toJid,
					IQTypes.GET,
					<query xmlns={DISCO_ITEMS_NS}/>,
					discoveryItemsHandler);
		}

		//-------------------------------
		// DISCOVERY ITEMS HANDLER
		//-------------------------------

		public function discoveryItemsHandler(iqStanza:IqStanza):void
		{
			
		}
	}
}