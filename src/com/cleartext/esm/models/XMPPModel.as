package com.cleartext.esm.models
{
	import com.cleartext.esm.events.ApplicationEvent;
	import com.cleartext.esm.events.FormEvent;
	import com.cleartext.esm.events.UserAccountEvent;
	import com.cleartext.esm.events.XmppErrorEvent;
	import com.cleartext.esm.models.types.ChatStateTypes;
	import com.cleartext.esm.models.types.IQTypes;
	import com.cleartext.esm.models.types.MicroBloggingServiceTypes;
	import com.cleartext.esm.models.types.SubscriptionTypes;
	import com.cleartext.esm.models.utils.LinkUitls;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.Contact;
	import com.cleartext.esm.models.valueObjects.FormField;
	import com.cleartext.esm.models.valueObjects.FormObject;
	import com.cleartext.esm.models.valueObjects.Message;
	import com.cleartext.esm.models.valueObjects.Status;
	import com.cleartext.esm.models.valueObjects.UserAccount;
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
	import mx.states.AddChild;
	
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

		namespace mucOwner = "http://jabber.org/protocol/muc#owner";
		public var MUC_OWNER_NS:String = "http://jabber.org/protocol/muc#owner";

		namespace mucUser = "http://jabber.org/protocol/muc#user";
		public var MUC_USER_NS:String = "http://jabber.org/protocol/muc#user";

		namespace vCardTemp = "vcard-temp";
		public var V_CARD_TEMP_NS:String = "vcard-temp";
		
		namespace jabberRoster = "jabber:iq:roster";
		public var JABBER_ROSTER_NS:String = "jabber:iq:roster";

		namespace jabberData = "jabber:x:data";
		public var JABBER_DATA_NS:String = "jabber:x:data";

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
		
		private function get buddies():ContactModel
		{
			return appModel.buddies;
		}
		
		private function get requests():BuddyRequestModel
		{
			return appModel.requests;
		}
		
		private function get chats():ChatModel
		{
			return appModel.chats;
		}
		
		private function get chatRooms():ChatRoomModel
		{
			return appModel.chatRooms;
		}
		
		private function get soundColor():SoundAndColorModel
		{
			return appModel.soundColor;
		}
		
		private function get avatarModel():AvatarModel
		{
			return appModel.avatarModel;
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
		// private var chatRoomNicknames:Dictionary = new Dictionary();
		
		// a dictionary to store the variables that we want to associate
		// with iq queries the key is the id of the iq stanza the we
		// are sending out
		private var iqVariables:Dictionary = new Dictionary();
		
		// flags to track progress during connecting
		private var gotAvatar:Boolean = false;
		private var gotRosterList:Boolean = false;

		// the seesmic xmpp object 
		private var xmpp:XMPP;
		
		public static const cleartextComponentPrefix:String = "cleartext.";
		public var cleartextComponentJid:String;
		public function get cleartextComponentHost():String
		{
			return cleartextComponentJid ? cleartextComponentJid.substr(cleartextComponentPrefix.length) : null;
		}
		public var twitterGatewayJid:String;
		
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
				xmpp.setServer(account.server, account.port);
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

	 		for each(var contact:Contact in buddies.buddies.source)
	 			contact.status.value = Status.OFFLINE;
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
					<query xmlns={JABBER_ROSTER_NS} ver='329eg'/>,
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
			var contact:Contact = appModel.getContactByJid(message.sender);
			
			// if the buddy does not exist in our buddy list, then treat it as a buddy
			// request
			if(!contact)
			{
				requests.receiving(message.sender, messageStanza.nick, message.plainMessage);
				database.saveMessage(message);
				return;
			}

			// if this is a message from a groupchat, then work out the 
			// sender's nickname
			if(contact is ChatRoom)
			{
				message.groupChatSender = event.stanza.from.resource;
			}
			// otherwise set the buddy's resource, we only save the message
			// if it isn't from a chatRoom
			else
			{
				if(contact is Buddy)
					(contact as Buddy).resource = messageStanza.from.resource;

				contact.status.isTyping = false;
				database.saveMessage(message);
			}

			contact.lastSeen = message.receivedTimestamp.time;
			if(!chats.selectedChat || chats.selectedChat.contact != contact)
				contact.unreadMessages++;
			chats.addMessage(contact, message);

			// play sounds & increment unread messages for the mblog buddy
			if(contact.isMicroBlogging)
			{
				if(chats.selectedChat && chats.selectedChat.contact != Buddy.ALL_MICRO_BLOGGING_BUDDY)
					Buddy.ALL_MICRO_BLOGGING_BUDDY.unreadMessages++;
				chats.addMessage(Buddy.ALL_MICRO_BLOGGING_BUDDY, message);
				soundColor.play(SoundAndColorModel.NEW_SOCIAL);
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
			var buddy:Buddy = appModel.getContactByJid(fromJid) as Buddy;

			if(buddy)
				buddy.status.isTyping = (chatState == ChatStateTypes.COMPOSING);
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
			var contact:Contact = appModel.getContactByJid(fromJid);
			
			// if this is our own presence we don't care
			if(fromJid == settings.userAccount.jid)
				return;
			
			var chatRoom:ChatRoom = contact as ChatRoom;
			// if this is from a chat room that we have asked to join
			if(chatRoom)
			{
				try
				{
					var x:Object = stanza.getXML().mucUser::x[0];
					
					if(x)
					{
						// if status code is 201, then send an iq telling the server
						// to create the room with default settings
						var status:Object = x.mucUser::status;
						if(status && status[0] && status[0].@code=='201')
						{
							sendIq(fromJid,
								IQTypes.SET,
								<query xmlns={MUC_OWNER_NS}><x xmlns={JABBER_DATA_NS} type="submit" /></query>,
								createDefaultChatRoomHandler,
								chatRoom);
							return;
						}
	
						var jid:String = x.mucUser::item[0].@jid;
						var index:int = jid.indexOf("/");
						if(index != -1)
							jid = jid.substr(0,index);
						
						
						chatRoom.setPresence(jid, stanza.type, stanza.from.resource, "");
					}
				}
				catch(e:Error)
				{
					appModel.log(e);
				}
				return;
			}

			// if this is a subscription request
			if(stanza.type == SubscriptionTypes.SUBSCRIBE)
			{
				// if there are in our rosterlist, then auto-subscirbe
				if(contact)
				{
					sendSubscribe(contact.jid, SubscriptionTypes.SUBSCRIBED);
					if((contact is Buddy) && !(contact as Buddy).subscribedTo)
						sendSubscribe(contact.jid, SubscriptionTypes.SUBSCRIBE);
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
				if(!contact)
				{
					// we don't care about you if you aren't in our roster list
					return;
				}
				
				var wasOffline:Boolean = contact.status.isOffline();
				
				if(contact is Buddy)
					(contact as Buddy).resource = stanza.from.resource;

				// setFromStanzaType also handles "unsubscribed" and "subscribed"
				// if there is an error, then reset the customStatus, otherwise
				// set the customStatus from the stanza
				var error:Boolean = contact.status.setFromStanzaType(stanza.type);
				contact.customStatus = (error) ? "" : stanza.status;
				
				// only set lastSeen if the buddy was offline or we are now 
				// explicitly going online
				if(wasOffline || contact.status.value == Status.AVAILABLE)
					contact.lastSeen = new Date().time;
				
				var avatarHash:String = stanza.avatarHash;
				if(avatarHash)
					avatarModel.setUrlOrHash(contact.jid, avatarHash);
				
				buddies.buddies.refresh();
				database.saveBuddy(contact);
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
			
			var contact:Contact;
			var buddiesToDelete:Dictionary = new Dictionary();
			
			for each(contact in buddies.buddies.source)
				if(!(contact is ChatRoom) && !(contact is BuddyGroup))
					buddiesToDelete[contact.jid] = contact;

			for each(var item:XML in stanza.query.jabberRoster::item)
			{
				var jid:String = item.@jid;
				
				// if we already have the buddy, then we just want to
				// update the values, otherwise create a new buddy
				contact = appModel.getContactByJid(jid);
				if(!contact)
					contact = new Buddy(jid);
				
				var b:Buddy = contact as Buddy;
				if(b)
				{
					var groups:Array = new Array();
					for each(var group:XML in item.jabberRoster::group)
						{
							var gString:String = String(group.text());
							if(gString != "")
								groups.push(gString);
						}
					b.groups = groups;

					b.subscription = item.@subscription;
					requests.setSubscription(jid, b.nickname, b.subscription);
				}
				
				contact.nickname = item.@name;
				avatarModel.getAvatar(jid).displayName = item.@name;

				// flag used to delete buddies that are no longer in
				// the roster list
				delete buddiesToDelete[contact.jid];
				
				// this adds, saves and adds an event listener to the buddy
				buddies.addBuddy(contact);
			}
			
			for each(contact in buddiesToDelete)
				buddies.removeBuddy(contact);

			gotRosterList = true;
			
			// discoveryItems() gives us a list of jids available on the server
			discoveryItems(settings.userAccount.host,
				function(jids:Array):void
				{
					for each(var j:String in jids)
						discoveryInfo(j, testForMicroBloggingComponents);
				});
		}
		
		//-------------------------------
		// ROSTER CHANGED HANDLER
		// 
		// called whenever the roster list changes
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
			var buddy:Buddy = appModel.getContactByJid(jid) as Buddy;
			
			// NOTE we want a Buddy - a roster item here, this could
			// lead to duplicates if someone adds a group or a chatroom
			// to their roster list
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
				buddy.nickname = event.stanza["name"];
				buddy.subscription = subscription;
				avatarModel.getAvatar(jid).displayName = event.stanza["name"];
				
				discoveryInfo(buddy.jid, testForMicroBloggingComponents);
				
				requests.setSubscription(jid, buddy.nickname, buddy.subscription);
			}
			buddies.refresh();
		}

		//-------------------------------
		// TEST FOR MICRO BLOGGING COMPONENTS
		//
		// Every time we get the roster list we get a list of transports on the server
		// and do a discovery info on them with this function as a handler. When
		// the server tells us that a new item is added to the roster we also do a
		// discovery info with this function as a handler.
		//-------------------------------
		
		private function testForMicroBloggingComponents(iqStanza:IqStanza):void
		{
			// if this is a cleartext microblogging component
			// then check it is in the roster list
			if(iqStanza.from == cleartextComponentPrefix + settings.userAccount.host)
			{
				cleartextComponentJid = iqStanza.from;
				var cleartextComponent:Contact = buddies.getBuddyByJid(cleartextComponentJid);
				// if this is in the roster list, then check we have the right
				// microBloggingServiceType
				if(cleartextComponent)
				{
					cleartextComponent.microBloggingServiceType = MicroBloggingServiceTypes.CLEARTEXT_MICROBLOGGING;
					var c:Boolean = false;
					if(cleartextComponent.nickname == cleartextComponent.jid)
					{
						cleartextComponent.nickname = "Cleartext MicroBlogging";
						avatarModel.getAvatar(cleartextComponentJid).displayName = "Cleartext MicroBlogging";
						c = true;
					}
					if(!cleartextComponent.isMicroBlogging)
					{
						cleartextComponent.isMicroBlogging = true;
						c = true;
					}
					if(c)
					{
						modifyRosterItem(cleartextComponent);
					}
				}
				// otherwise add it to the roster
				else
				{
					cleartextComponent = new Buddy(cleartextComponentJid);
					cleartextComponent.nickname = "Cleartext MicroBlogging";
					cleartextComponent.microBloggingServiceType = MicroBloggingServiceTypes.CLEARTEXT_MICROBLOGGING;
					cleartextComponent.isMicroBlogging = true;
					buddies.addBuddy(cleartextComponent);
					addToRoster(cleartextComponent);
					avatarModel.getAvatar(cleartextComponentJid).displayName = "Cleartext MicroBlogging";
				}
			}
			else if(iqStanza.query.discoInfo::identity)
			{
				// if this is the status one twitter gateway, then set
				// the twitterGatewayJid
				var identity:XML = iqStanza.query.discoInfo::identity[0];
				if(identity && identity.@category == "gateway" && identity.@type == "twitter")
				{
					twitterGatewayJid = iqStanza.from;

					// if we have the twitter gataway in the roster
					// then make sure it has the right settings
					if(buddies.containsJid(twitterGatewayJid))
					{
						var twitterGateway:Contact = buddies.getBuddyByJid(twitterGatewayJid);
						twitterGateway.microBloggingServiceType = MicroBloggingServiceTypes.STATUS_ONE_TWITTER;

						var change:Boolean = false;
						if(twitterGateway.nickname == twitterGateway.jid)
						{
							twitterGateway.nickname = "Twitter";
							avatarModel.getAvatar(twitterGatewayJid).displayName = "Twitter";
							change = true;
						}
						if(!twitterGateway.isMicroBlogging)
						{
							twitterGateway.isMicroBlogging = true;
							change = true;
						}
						if(change)
						{
							modifyRosterItem(twitterGateway);
						}
					}
				}
			}
		}
		
		//-------------------------------
		// ADD TO ROSTER 
		//-------------------------------
		
		public function addToRoster(buddy:Contact):void
		{
			var query:XML = <query xmlns={JABBER_ROSTER_NS} />;
			var item:XML = <item jid={buddy.jid} />;
			if(buddy.nickname != buddy.jid)
				item.@name = buddy.nickname;
			
			if(buddy is Buddy)
			{
				var groups:Array = (buddy as Buddy).groups;
				for each(var group:String in groups)
					item.appendChild(<group>{group}</group>);
			}
			
			query.appendChild(item);

			sendIq(settings.userAccount.jid,
					IQTypes.SET,
					query,
					addToRosterHandler,
					buddy.jid);
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
				chats.getChat(appModel.getContactByJid(toJid), true);
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
		
		public function modifyRosterItem(buddy:Contact):void
		{
			var query:XML = <query xmlns={JABBER_ROSTER_NS} />;
			var item:XML = <item jid={buddy.jid}/>
			
			if(buddy is Buddy)
				 item.@subscription=(buddy as Buddy).subscription;

			if(buddy.nickname != buddy.jid)
				item.@name = buddy.nickname;
			
			if(buddy is Buddy)
			{
				var groups:Array = (buddy as Buddy).groups;
				for each(var group:String in groups)
					item.appendChild(<group>{group}</group>);
			}
			
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

		//-------------------------------
		//  IS TWITTER GATEWAY
		//-------------------------------
		
		private function isTwitterGateway(jid:String):Boolean
		{
			return false;
		}
		
		//------------------------------------------------------------------
		//
		//   VCARD HANDLERS
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		// GET VCARD
		//-------------------------------
		
		public function getVCard(jid:String):void
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
			var xml:XML = stanza.getXML();
			
			var buddyJid:String = stanza.from;
			
			// if we are downloading our v-card from the server
			if(buddyJid == settings.userAccount.jid)
			{
				gotAvatar = true;
				var vCard:XMLList = xml.vCardTemp::vCard;
				var serverAvatar:String = vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				var localAvatar:String = avatarModel.userAccountAvatar.bitmapString;
				
				// if we have a different avatar to the one on the server, then send a
				// vcard back to the server
				if(serverAvatar != localAvatar && localAvatar != "" && localAvatar != "null")
				{
					vCard.vCardTemp::PHOTO.vCardTemp::BINVAL = localAvatar;
					sendIq(settings.userAccount.jid, IQTypes.SET, vCard[0]);
				}
				else if(localAvatar == "" || localAvatar == "null")
				{
					// make sure the hash is also set !!
					avatarModel.setBitmapString("userAccount", serverAvatar);
				}

				// now we have the avatar, resend the presence to make sure the 
				// avatar hash is sent to our buddies
				sendPresence();
			}
			else
			{
				var avatarString:String = xml.vCardTemp::vCard.vCardTemp::PHOTO.vCardTemp::BINVAL;
				avatarModel.setBitmapString(buddyJid, avatarString);
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
			avatarModel.setBitmapString(buddyJid, avatarString);
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
				xmpp.sendPresence(customStatus, status.toShow(), priority, toJid, (gotAvatar) ? avatarModel.userAccountAvatar.urlOrHash : "");
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
			var msg:MessageStanza = xmpp.sendMessage(toJid, body, subject, type, chatState, customTags);
			msg.body = LinkUitls.escapeHTML(msg.body);
			return msg;
		}
		
		//------------------------------------------------------------------
		//
		//   SEND SUBSCRIBE / BLOCK
		//
		//------------------------------------------------------------------
		
		public function sendSubscribe(toJid:String, type:String):void
		{
			var xmlString:String = '<presence to="' + toJid + '" type="' + type;
			
			if(type == SubscriptionTypes.SUBSCRIBE)
			{
				requests.sending(toJid);
				xmlString += '"><nick xmlns="http://jabber.org/protocol/nick">' + settings.userAccount.nickname + '</nick></presence>';
			}
			else
			{
				xmlString += '" />';
			}

			xmpp.send(xmlString);
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
		// CREATE CHAT ROOM
		//-------------------------------
		
		public function createChatRoom(roomJid:String):void
		{
			sendIq(roomJid,
					IQTypes.GET,
					<query xmlns={MUC_OWNER_NS}/>,
					createChatRoomHandler);
		}
		
		//-------------------------------
		// CREATE CHAT ROOM HANDLER
		//-------------------------------
		
		public function createChatRoomHandler(iqStanza:IqStanza):void
		{
			var x:Object = iqStanza.query.mucOwner::x;
			if(x && x[0])
				Swiz.dispatchEvent(new FormEvent(FormEvent.NEW_FORM, createForm(x[0], iqStanza.from)));
			else
				Swiz.dispatchEvent(new XmppErrorEvent(XmppErrorEvent.ERROR, "unable to create new chat room at " + iqStanza.from, iqStanza.from, iqStanza.error));
		}
		
		//-------------------------------
		// JOIN CHAT ROOM
		//-------------------------------
		
		public function joinChatRoom(roomJid:String, nickname:String, password:String=""):void
		{
			xmpp.send('<presence to="' + roomJid + "/" + nickname + '">' + (password=="" ? '' : '<password>' + password + '</password>') + "<x xmlns='" + MUC_NS + "'/></presence>");
		}
		
		//-------------------------------
		// LEAVE CHAT ROOM
		//-------------------------------
		
		public function leaveChatRoom(roomJid:String, nickname:String):void
		{
			xmpp.send('<presence type="unavailable" to="' + roomJid + "/" + nickname +'" />');
		}
		
		//-------------------------------
		// CREATE DEFAULT CHAT ROOM
		//-------------------------------
		
		private function createDefaultChatRoomHandler(stanza:IqStanza):void
		{
			var id:String = stanza.id;
			if(iqVariables.hasOwnProperty(id))
			{
				var chatRoom:ChatRoom = iqVariables[id] as ChatRoom;
				chatRoom.status.value = Status.AVAILABLE;
				chats.getChat(chatRoom, true);
			}
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
		
		//-------------------------------
		// DISCOVERY INFO
		//-------------------------------

		public function discoveryInfo(toJid:String, handler:Function=null):void
		{
			sendIq(toJid,
					IQTypes.GET,
					<query xmlns={DISCO_INFO_NS}/>,
					discoveryInfoHandler,
					handler);
		}
		
		//-------------------------------
		// DISCOVERY INFO HANDLER
		//-------------------------------

		public function discoveryInfoHandler(iqStanza:IqStanza):void
		{
			var fromJid:String = iqStanza.from;
			var bareJid:String = (fromJid.indexOf("/") == -1) ? fromJid : fromJid.substr(0, fromJid.indexOf("/"));
			var buddy:Buddy = appModel.getContactByJid(bareJid) as Buddy;

			if(iqStanza.query)
			{
				var featuresXML:XMLList = iqStanza.query.discoInfo::feature as XMLList;
				if(buddy && featuresXML && featuresXML.length() > 0)
				{
					for each(var feature:XML in featuresXML)
					{
						var ns:String = feature.attribute("var").toString();
						buddy.features.push(ns);
					}
				}
				
				var id:String = iqStanza.id;
				if(iqVariables.hasOwnProperty(id))
				{
					(iqVariables[id] as Function)(iqStanza);
					delete iqVariables[id];
				}
			}
		}
		
		//-------------------------------
		// DISCOVERY ITEMS
		//-------------------------------

		public function discoveryItems(toJid:String, handler:Function):void
		{
			sendIq(toJid,
					IQTypes.GET,
					<query xmlns={DISCO_ITEMS_NS}/>,
					discoveryItemsHandler,
					handler);
		}

		//-------------------------------
		// DISCOVERY ITEMS HANDLER
		//-------------------------------

		public function discoveryItemsHandler(iqStanza:IqStanza):void
		{
			if(iqStanza.query)
			{
				var items:XMLList = iqStanza.query.discoItems::item as XMLList;
				var result:Array = new Array();
				for each(var item:XML in items)
				{
					result.push(item.@jid.toString());
				}

				var id:String = iqStanza.id;
				if(iqVariables.hasOwnProperty(id))
				{
					(iqVariables[id] as Function)(result);
					delete iqVariables[id];
				}
			}
		}
		
		//------------------------------------------------------------------
		//
		//   TRANSPORTS
		//
		//------------------------------------------------------------------
				
		//-------------------------------
		//  ADD TRANSPORT
		//-------------------------------

		public function addTransport(toJid:String, handler:Function=null):void
		{
			sendIq(toJid,
					IQTypes.GET,
					<query xmlns={JABBER_REGISTER_NS}/>,
					addTransportHandler,
					handler);
		}
		
		//-------------------------------
		//  ADD TRANSPORT HANDLER
		//-------------------------------

		public function addTransportHandler(iqStanza:IqStanza):void
		{
			var handler:Function = iqVariables[iqStanza.id];
			if(handler != null)
			{
				handler(iqStanza);
				return;
			}
			
			var x:Object = iqStanza.query.jabberData::x;
			if(x && x[0])
				Swiz.dispatchEvent(new FormEvent(FormEvent.NEW_FORM, createForm(x[0], iqStanza.from)));
			else
				Swiz.dispatchEvent(new XmppErrorEvent(XmppErrorEvent.ERROR, "unable to connect to " + iqStanza.from, iqStanza.from, iqStanza.error));
		}
		
		//------------------------------------------------------------------
		//
		//   FORMS
		//
		//------------------------------------------------------------------
		
		//-------------------------------
		//  CREATE FORM
		//-------------------------------

		public function createForm(xml:Object, fromJid:String):FormObject
		{
			var form:FormObject = new FormObject();
			form.instructions = xml.jabberData::instructions;
			form.title = xml.jabberData::title;
			form.from = fromJid;
			
			var fields:XMLList = xml.jabberData::field;
			if(fields)
			{
				for each(var field:Object in fields)
				{
					var f:FormField = new FormField();
					f.label = field.@label;
					f.type = field.@type;
					if(field.jabberData::value)
						f.value = field.jabberData::value;
					f.varName = field.attribute("var").toString();
					f.required = field.hasOwnProperty("required");
					form.fields.push(f);
				}
			}
			return form;
		}
		
		//-------------------------------
		//  SUBMIT FORM
		//-------------------------------

		public function submitForm(form:FormObject, handler:Function=null):void
		{
			var query:XML = <query xmlns={JABBER_REGISTER_NS} />;
			var xData:XML = <x xmlns={JABBER_DATA_NS} type='submit'/>;
			
			for each(var field:FormField in form.fields)
			{
				if(field.varName)
					xData.appendChild(<field type={field.type} var={field.varName}><value>{field.value}</value></field>);
			}
			
			query.appendChild(xData);
			
			sendIq(form.from,
				IQTypes.SET,
				query,
				submitFormHandler,
				handler);
		}

		//-------------------------------
		//  SUBMIT FORM HANDLER
		//-------------------------------

		public function submitFormHandler(iqStanza:IqStanza):void
		{
			var handler:Function = iqVariables[iqStanza.id];
			if(handler != null)
			{
				handler(iqStanza);
			}
			else if(iqStanza.type=='error')
			{
				Swiz.dispatchEvent(new XmppErrorEvent(XmppErrorEvent.ERROR, "Sorry, " + iqStanza.from + " refused your form, please try again.", iqStanza.from, iqStanza.error));
			}
		}
	}
}