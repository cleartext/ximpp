package com.cleartext.esm.models
{
	import com.cleartext.esm.events.LoadingEvent;
	import com.cleartext.esm.models.types.MicroBloggingServiceTypes;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.BuddyRequest;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	import com.cleartext.esm.models.valueObjects.Contact;
	import com.cleartext.esm.models.valueObjects.DatabaseValue;
	import com.cleartext.esm.models.valueObjects.Message;
	import com.cleartext.esm.models.valueObjects.UserAccount;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class DatabaseModel extends EventDispatcher
	{
		private var maxTimeForProcess:int = 20;
		private var timeout:int = 1;
		
		private var chatsToLoad:Array;
		private var chatIndex:int = 0;
		
		/*
		 * synchronous and asynchronous database connections
		 */
		private var syncConn:SQLConnection;
		
		private var imageQueue:Dictionary = new Dictionary();
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel; 
		
		private function get settings():SettingsModel
		{
			return appModel.settings;
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
				
		private function get avatarModel():AvatarModel
		{
			return appModel.avatarModel;
		}
				
		public function close():void
		{
			appModel.log("Closing sync database connection")
			if(syncConn)
				syncConn.close();
		}
		
		/**
		 * create the database file and make sure the appropriate tables exist
		 */
		public function createDatabase():void
		{
			try
			{
				appModel.log("Creating and opening database", true);
				// create the local database file
				 var dbName:String = "ximpp.db";
				// dbName = "ximpp32.db";
				// dbName = new Date().time + ".db";
				
				var dbFile:File = File.applicationStorageDirectory.resolvePath(dbName);
				appModel.log("DB Location: " + dbFile.nativePath);
				
				// link the sync connection to the file
				appModel.log("Opening sync database connection");
				syncConn = new SQLConnection();
				syncConn.open(dbFile, SQLMode.CREATE, true);
				syncConn.addEventListener(SQLErrorEvent.ERROR, appModel.log, false, 0, true);

				var sql:String;
				
				/*
				 * create the user accounts table
				 */
				appModel.log("Creating user settings table", true);
				execute(UserAccount.CREATE_USER_ACCOUNTS_TABLE);
				
				/*
				 * check there is at least one user account
				 */
				appModel.log("Checking user account exist");
				execute("INSERT INTO userAccounts (userId) " + 
					"SELECT 1 " + 
					"WHERE NOT EXISTS (SELECT 1 FROM userAccounts WHERE userId=1)");

				/*
				 * create messages table
				 */
				appModel.log("Creating messages table", true);
				execute(Message.CREATE_MESSAGES_TABLE);
				
				/*
				 * Create buddy table
				 */
				appModel.log("Creating buddy table", true);
				execute(Buddy.CREATE_BUDDIES_TABLE);
				
				/*
				 * Create buddyRequests table
				 */
				appModel.log("Creating buddyRequests table", true);
				execute(BuddyRequest.CREATE_BUDDY_REQUESTS_TABLE);
				
				/*
				 * Create avatars table
				 */
				appModel.log("Creating avatars table", true);
				execute(Avatar.CREATE_AVATARS_TABLE);
				
				var mods:Array;
				var column:SQLColumnSchema;
				var mod:Object;
				var i:int;
				
				syncConn.loadSchema();
				var schema:SQLSchemaResult = syncConn.getSchemaResult();
				for each (var table:SQLTableSchema in schema.tables)
				{
					// ------------------------------------------
					// BUDDY TABLE MODS
					// ------------------------------------------
					
					if(table.name == "buddies")
					{
						mods = Buddy.TABLE_MODS.slice();
						
						for each(column in table.columns)
							for(i=0; i<mods.length; i++)
								if(column.name == mods[i].name)
									mods.splice(i,1);
						
						for each(mod in mods)
						{
							sql = "ALTER TABLE buddies ADD COLUMN " + mod.name + " " + mod.type;
							if(mod.hasOwnProperty("defaultVal"))
								sql += " DEFAULT " + mod.defaultVal;
							appModel.log("Updating buddy table structure", true);
							execute(sql);
						}
					}
					
					// ------------------------------------------
					// USER ACCOUNT TABLE MODS
					// ------------------------------------------
					
					else if(table.name == "userAccounts")
					{
						mods = UserAccount.TABLE_MODS.slice();
						
						var hasAvatar:Boolean = false;
						for each(column in table.columns)
						{
							for(i=0; i<mods.length; i++)
							{
								if(column.name == mods[i].name)
									mods.splice(i,1);
								else if(column.name == "timestamp")
									hasAvatar = true;
							}
						}
						
						for each(mod in mods)
						{
							sql = "ALTER TABLE userAccounts ADD COLUMN " + mod.name + " " + mod.type;
							if(mod.hasOwnProperty("defaultVal"))
								sql += " DEFAULT " + mod.defaultVal;
							appModel.log("Updating userAccount table structure", true);
							execute(sql);
						}
						
					}
					
//					// ------------------------------------------
//					// MICRO BLOGGING BUDDY TABLE MODS
//					// ------------------------------------------
//
//					else if(table.name == "microBloggingBuddies")
//					{
//						mods = MicroBloggingBuddy.TABLE_MODS.slice();
//						
//						for each(column in table.columns)
//							for(i=0; i<mods.length; i++)
//								if(column.name == mods[i].name)
//									mods.splice(i,1);
//						
//						for each(mod in mods)
//						{
//							sql = "ALTER TABLE microBloggingBuddies ADD COLUMN " + mod.name + " " + mod.type;
//							if(mod.hasOwnProperty("defaultVal"))
//								sql += " DEFAULT " + mod.defaultVal;
//							appModel.log("Updating microBloggingBuddies table structure", true);
//							execute(sql);
//						}
//					}
					
					// ------------------------------------------
					// MESSAGE TABLE MODS
					// ------------------------------------------
					
					else if(table.name == "messages")
					{
						var hasTimestamp:Boolean = false;
						mods = Message.TABLE_MODS.slice();
						for each(column in table.columns)
						{
							for(i=0; i<mods.length; i++)
							{
								if(column.name == mods[i].name)
									mods.splice(i,1);
								else if(column.name == "timestamp")
									hasTimestamp = true;
							}
						}

						for each(mod in mods)
						{
							sql = "ALTER TABLE messages ADD COLUMN " + mod.name + " " + mod.type;
							if(mod.hasOwnProperty("defaultVal"))
								sql += " DEFAULT " + mod.defaultVal;
							appModel.log("Updating message table structure", true);
							execute(sql);
						}
						
						if(hasTimestamp)
						{
							// find out the receivedTimestamp based on timestamp
							appModel.log("Setting receivedTimestamp feild", true);
							sql = "UPDATE messages SET receivedTimestamp=strftime('%s',timestamp)*1000 WHERE receivedTimestamp is null";
							execute(sql);
							
							// find out the sentTimestamp based on timestamp
							appModel.log("Setting sentTimestamp feild", true);
							sql = "UPDATE messages SET sentTimestamp=strftime('%s',timestamp)*1000 WHERE sentTimestamp is null";
							execute(sql);
							
							// compact now cause we are about to do a lot of work on the db
							syncConn.compact();
							
							// start transaction 
							syncConn.begin();
							
							var stmt:SQLStatement = new SQLStatement();
							stmt.sqlConnection = syncConn;
							
							// create a temporary table
							stmt.text = "CREATE TEMPORARY TABLE messages_tmp(" +
								"messageId INTEGER PRIMARY KEY AUTOINCREMENT, " +
								"userId INTEGER, " +
								"sender TEXT, " +
								"recipient TEXT, " +
								"type TEXT, " +
								"subject TEXT, " +
								"plainMessage TEXT, " +
								"displayMessage TEXT, " + 
								"senderId INTEGER, " +
								"originalSenderId INTEGER, " +
								"rawxml TEXT," +
								"sentTimestamp NUMERIC, " +
								"receivedTimestamp NUMERIC);";
							stmt.execute();
							
							// copy across the values we want (everything except timestamp)
							stmt.text = "INSERT INTO messages_tmp SELECT " +
								"messageId, userId, " +
								"sender, recipient, " +
								"type, subject, " +
								"plainMessage, displayMessage, " +
								"senderId, originalSenderId, " +
								"rawxml, sentTimestamp, " +
								"receivedTimestamp FROM messages";
							stmt.execute();
							
							// get rid of original table
							stmt.text = "DROP TABLE messages";
							stmt.execute();
							
							// create nice new table
							stmt.text = Message.CREATE_MESSAGES_TABLE;
							stmt.execute();
							
							// copy across old valuse
							stmt.text = "INSERT INTO messages SELECT * FROM messages_tmp";
							stmt.execute();
							
							// get rid of temporary table
							stmt.text = "DROP TABLE messages_tmp";
							stmt.execute();
							
							// done !! - so commit transaction and compact again
							syncConn.commit();
							syncConn.compact();
						}
					}
				}
				
				// add all the indexes on jid fields
				execute("CREATE INDEX IF NOT EXISTS avatarJids ON avatars (jid)");
				execute("CREATE INDEX IF NOT EXISTS senders ON messages (sender)");
				execute("CREATE INDEX IF NOT EXISTS recipients ON messages (recipient)");
				
				appModel.log("Database successfully created", true);
			}
			catch (error:Error)
			{
				appModel.log(error, true);
				appModel.fatalError("Could not create database.");
			}
		}

		/**
		 * Load user settings
		 */
		public function loadUserSettings(newUserId:int):void
		{
			appModel.log("Loading user settings", true);
			var result:SQLResult = execute("SELECT * FROM userAccounts WHERE userId=" + newUserId);
			if (result && result.data)
				settings.userAccount = UserAccount.createFromDB(result.data[0]);
			else
				appModel.fatalError("no user account with id: " + newUserId);
		}
		
		/**
		 * Load global settings
		 */
		public function loadGlobalSettings():void
		{
			settings.global.load();
			loadUserSettings(1);
		}

		private function createIBuddy(obj:Object):Contact
		{
			var type:String = obj["buddyType"];

			var newContact:Contact;
			switch(type)
			{
				case "group" :
					var group:BuddyGroup = new BuddyGroup(obj["jid"]);
					group.refresh(buddies);
					newContact = group;
					break;
				case "chatRoom" :
					var chatRoom:ChatRoom = new ChatRoom(obj["jid"]);
					var np:Array = (obj["groups"] as String).split(",");
					chatRoom.ourNickname = np[0];
					chatRoom.password = np[1];
					newContact = chatRoom;
					break;
				default :
					var buddy:Buddy = new Buddy(obj["jid"]);
					var groups:Array = (obj["groups"] as String).split(",");
					if(groups.length == 1 && groups[0] == "")
						groups = [];
					buddy.groups = groups;
					buddy.sendTo = obj["sendTo"];
					buddy.subscription = obj["subscription"];
					newContact = buddy;
					break;
			}
			
			newContact.buddyId = obj["buddyId"];
			newContact.nickname = obj["nickName"];
			newContact.lastSeen = obj["lastSeen"];
			newContact.customStatus = obj["customStatus"];
			newContact.openTab = obj["openTab"];
			newContact.autoOpenTab = obj["autoOpenTab"];
			newContact.unreadMessages = obj["unreadMessages"];
			newContact.microBloggingServiceType = obj["microBloggingServiceType"];
			
			var avatar:Avatar = avatarModel.getAvatar(newContact.jid);
			avatar.displayName = newContact.nickname;
			
			if(MicroBloggingServiceTypes.TYPES.indexOf(newContact.microBloggingServiceType) == -1)
				newContact.microBloggingServiceType = MicroBloggingServiceTypes.OTHER;
			return newContact;
		}
		
		public function loadBuddyData(data:Array=null, index:int=0):void
		{
			var start:int = getTimer();
			
			if(data)
			{
				while(index>=0)
				{
					buddies.addBuddy(createIBuddy(data[index]), false);
					index--;
					if(start + maxTimeForProcess < getTimer())
					{
						var len:int = data.length;
						dispatchEvent(new LoadingEvent(LoadingEvent.BUDDIES_LOADING, len-index, len));
						setTimeout(loadBuddyData, timeout, data, index);
						return;
					}
				}
				
				buddies.refresh();
				dispatchEvent(new LoadingEvent(LoadingEvent.BUDDIES_LOADED));
			}
			else
			{
				try
				{
					appModel.log("Loading buddy requests", true);
					result = execute("Select * from buddyRequests WHERE userid=" + settings.userId + " ORDER BY timestamp ASC");
					if(result && result.data)
						for(var j:int=result.data.length-1; j>=0; j--)
							requests.addRequest(BuddyRequest.createFromDB(result.data[j]));

					appModel.log("Loading buddies", true);
					var result:SQLResult = execute("Select buddyId, userId, jid, nickname, groups, lastSeen, subscription, sendTo, customStatus, openTab, autoOpenTab, unreadMessages, buddyType, microBloggingServiceType from buddies WHERE userid=" + settings.userId + " ORDER BY lastSeen DESC");
					
					if(result && result.data)
						loadBuddyData(result.data, result.data.length-1);
					else
						dispatchEvent(new LoadingEvent(LoadingEvent.BUDDIES_LOADED));
				}
				catch (e:Error)
				{
					appModel.log(e);
				}
			}
		}
				
		public function getAllUserAccounts():ArrayCollection
		{
			appModel.log("Loading user accounts", true);
			var result:SQLResult = execute("SELECT * FROM userAccounts");
		   	var accounts:ArrayCollection = new ArrayCollection();
			if (result && result.data)
			{
				var len:int = result.data.length;
				for(var i:int=0; i<len; i++)
					accounts.addItem(UserAccount.createFromDB(result.data[i]));
			}
			return accounts;
		}
		
		public function removeAccount(userId:int):void
		{
			appModel.log("Deleting user account", true);
			execute("DELETE FROM userAccounts WHERE userId = " + userId);
		}
		
		public function saveGlobalSettings():void
		{
			appModel.log("Saving global settings", true);
			settings.global.save();
		}
		
		public function saveUserAccount(userAccount:UserAccount):void
		{
			appModel.log("Saving user account : " + userAccount.accountName + " userId: " + userAccount.userId, true);
			
			var values:Array = userAccount.toDatabaseValues(userAccount.userId);
			
			if(userAccount.userId == -1)
				userAccount.userId = insertStmt("userAccounts", values);
			else
				updateStmt("userAccounts", values, [new DatabaseValue("userId", userAccount.userId)]);
		}
		
		public function saveBuddy(contact:Contact):void
		{
			appModel.log("Saving buddy : " + contact.jid + " buddyId: " + contact.buddyId, true);
			if(contact == Buddy.ALL_MICRO_BLOGGING_BUDDY || contact is UserAccount)
				return;
			
			if(contact.buddyId == -1)
				contact.buddyId = insertStmt("buddies", contact.toDatabaseValues(settings.userId));
			else
				updateStmt("buddies", contact.toDatabaseValues(settings.userId), [new DatabaseValue("buddyId", contact.buddyId)]);
		}

		public function saveRequest(request:BuddyRequest):void
		{
			appModel.log("Saving buddy request : " + request.jid + " incoming: " + request.incomming, true);

			if(request.buddyRequestId == -1)
				request.buddyRequestId = insertStmt("buddyRequests", request.toDatabaseValues(settings.userId));
			else
				updateStmt("buddyRequests", request.toDatabaseValues(settings.userId), [new DatabaseValue("buddyRequestId", request.buddyRequestId)]);
		}

//		public function saveMicroBloggingBuddy(buddy:MicroBloggingBuddy):void
//		{
//			appModel.log("Saving microblogging buddy : "  + buddy.jid + " micoBloggingBuddyId: " + buddy.microBloggingBuddyId, true);
//			updateStmt("microBloggingBuddies", buddy.toDatabaseValues(), [new DatabaseValue("microBloggingBuddyId", buddy.microBloggingBuddyId)]);
//		}
		
		public function saveAvatar(avatar:Avatar):void
		{
			appModel.log("Saving avatar : " + avatar.jid + " avatarId: " + avatar.avatarId, true);

			if(avatar.avatarId == -1)
				avatar.avatarId = insertStmt("avatars", avatar.toDatabaseValues(settings.userId));
			else
				updateStmt("avatars", avatar.toDatabaseValues(settings.userId), [new DatabaseValue("avatarId", avatar.avatarId)]);
		}

		public function removeBuddy(contact:Contact):void
		{
			appModel.log("Deleting buddy : " + contact.jid + " buddyId: " + contact.buddyId, true);
			execute("DELETE FROM buddies WHERE buddyId = " + contact.buddyId);
		}
		
		public function removeRequest(request:BuddyRequest):void
		{
			appModel.log("Deleting buddyRequest : " + request.jid, true);
			execute("DELETE FROM buddyRequests WHERE buddyRequestId = " + request.buddyRequestId);
		}
		
		public function saveMessage(message:Message):void
		{
			appModel.log("Save message from: " + message.sender + " to: " + message.recipient, true);
			message.messageId = insertStmt("messages", message.toDatabaseValues(settings.userId));
		}
		
		public function loadChats(chatsToOpen:Array, index:int=0):void
		{
			var start:int = getTimer();
			var len:int = chatsToOpen.length;
			while(index < len)
			{
				chats.getChat(chatsToOpen[index] as Contact);
				index++;
				if(start + maxTimeForProcess < getTimer())
				{
					dispatchEvent(new LoadingEvent(LoadingEvent.CHATS_LOADING, index, len));
					setTimeout(loadChats, timeout, chatsToOpen, index);
					return;
				}
			}
			dispatchEvent(new LoadingEvent(LoadingEvent.CHATS_LOADED));
		}
		
		public function loadMessages(chat:Chat, syncnonusly:Boolean=true):void
		{
			var contact:Contact = chat.contact;
			var buddyArray:Array = (contact == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? buddies.microBloggingBuddies.toArray() : [contact];
			if(buddyArray.length == 0)
			{
				if(contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADED));
				return;
			}

			appModel.log("Loading messages with " + chat.contact.jid, true);
			var sql:String = "Select * from messages WHERE userid=" + settings.userId + " AND (";
			
			for each(var c:Contact in buddyArray)
			{
				sql += "sender='" + c.jid + "' OR recipient='" + c.jid + "' OR ";
			}

			sql = sql.substr(0, sql.length-4);
			sql += ") ORDER BY " + 
					((settings.global.sortBySentDate) ? "sentTimestamp" : "receivedTimestamp") + 
					" DESC LIMIT 0," + 
					((contact == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? settings.global.numTimelineMessages : settings.global.numChatMessages);
			
			var result:SQLResult = execute(sql);

			if(result && result.data)
			{
				var sort:Sort = new Sort();
				sort.fields = [new SortField("sortDate", false, true)];
				chat.messages.sort = sort;
				if(syncnonusly)
				{
					for(var i:int = result.data.length-1; i>=0; i--)
					{
						chat.messages.addItem(Message.createFromDB(result.data[i]));
					}
					dispatchEvent(new LoadingEvent(LoadingEvent.CHAT_LOADED));
				}
				else
				{
					loopOverMessages(result.data, 0, chat);
				}
			}
			else if(chat.contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
			{
				dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADED));
			}
			else
			{
				dispatchEvent(new LoadingEvent(LoadingEvent.CHAT_LOADED));
			}
		}
		
		private function loopOverMessages(data:Array, index:int, chat:Chat):void
		{
			var start:int = getTimer();

			var len:int = data.length;
			while(index < len)
			{
				chat.messages.addItem(Message.createFromDB(data[index]));
				index++;
				if(start + maxTimeForProcess < getTimer())
				{
					if(chat.contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					{
						dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADING, index-1, len));
					}
					setTimeout(loopOverMessages, timeout, data, index, chat);
					return;
				}
			}
			
			if(chat.contact == Buddy.ALL_MICRO_BLOGGING_BUDDY)
			{
				dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADED));
			}
		}
		
		public function loadAvatar(jid:String):Avatar
		{
			appModel.log("Loading avatar for jid: (" + jid + ")");
			var sql:String = "SELECT * from avatars WHERE jid='" + jid + "'";
			
			var result:SQLResult = execute(sql);
			
			if (result && result.data)
			{
				var obj:Object = result.data[0];
				return Avatar.createFromDB(obj, avatarModel.bitmapDataFromString(obj["bitmapString"]));
			}
			return null;
		}
		
		private function insertStmt(table:String, values:Array):int
		{
			var start:int = getTimer();
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			
			var sql:String = "INSERT INTO " + table + " (";
			var renderedSql:String = "SQL : " + sql;

			var valuesString:String = ") VALUES (";
			var renderedValuesString:String = valuesString;
			
			var firstTime:Boolean = true;
			for each(var value:DatabaseValue in values)
			{
				if(firstTime)
				{
					firstTime = false;
				}
				else
				{
					sql += ", ";
					valuesString += ", ";
					renderedSql += ", ";
					renderedValuesString += ", ";
				}

				sql += value.columnName;
				renderedSql += value.columnName;

				valuesString += value.param;
				renderedValuesString += "(" + value.value + ")";
				stmt.parameters[value.param] = value.value;
			}
			
			renderedSql += renderedValuesString + ")";
			appModel.log(renderedSql);

			sql += valuesString + ")";
			stmt.text = sql;
			stmt.execute();
			syncConn.commit();
			appModel.log("SQL : QUERY DURATION : " + (getTimer() - start));
			
			return stmt.getResult().lastInsertRowID;
		}
		
		private function updateStmt(table:String, values:Array, criteria:Array):void
		{
			if(!table || !values)
				return;
			
			var start:int = getTimer();
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			
			var sql:String = "UPDATE " + table + " SET ";
			var renderedSql:String = "SQL : " + sql;
			
			var firstTime:Boolean = true;
			for each(var v:DatabaseValue in values)
			{
				if(firstTime)
				{
					firstTime = false;
				}
				else
				{
					sql += ", ";
					renderedSql += ", ";
				}
				
				sql += v.setParameter(stmt);
				renderedSql += v.renderParameter();
			}
			
			firstTime = true;
			for each(var c:DatabaseValue in criteria)
			{
				if(firstTime)
				{
					sql += " WHERE ";
					renderedSql += " WHERE "
					firstTime = false;
				}
				else
				{
					sql += " AND ";
					renderedSql += " AND ";
				}

				sql += c.setParameter(stmt);
				renderedSql += c.renderParameter();
			}
			stmt.text = sql;
			appModel.log(renderedSql);
			stmt.execute();
			syncConn.commit();
			appModel.log("SQL : QUERY DURATION : " + (getTimer() - start));
		}
		
//		public function getMicroBloggingBuddy(idOrUserName:Object, gatewayJid:String=null):MicroBloggingBuddy
//		{
//			var traceStr:String = idOrUserName + (gatewayJid ? ("@" + gatewayJid) : "");
//			var sql:String = "Select * from microBloggingBuddies WHERE ";
//			
//			if(!gatewayJid)
//				sql += "microBloggingBuddyId=" + idOrUserName;
//			else
//				sql += "userName='" + idOrUserName + "' AND gatewayJid='" + gatewayJid + "'";
//		
//			appModel.log("Loading microBloggingBuddy : " + traceStr, true);
//			var result:SQLResult = execute(sql);
//
//			if(result && result.data && result.data.length > 0)
//				return MicroBloggingBuddy.createFromDB(result.data[0]);
//			
//			// now we have to create a new buddy
//			if(!gatewayJid)
//				throw new Error("need a gatewayJid");
//
//			var buddy:MicroBloggingBuddy = new MicroBloggingBuddy();
//			buddy.userName = idOrUserName as String;
//			buddy.gatewayJid = gatewayJid;
//
//			appModel.log("Creating new microBloggingBuddy : " + traceStr, true);
//			buddy.microBloggingBuddyId = insertStmt("microBloggingBuddies", buddy.toDatabaseValues());
//			
//			return buddy;
//		}
		
		public function searchMessages(searchTerms:Array):Array
		{
			var sortType:String = (settings.global.sortBySentDate) ? "sentTimestamp" : "receivedTimestamp";
			
			// start a transaction 
			appModel.log("Loading messages with searchTerms " + searchTerms.join(", "), true);
			
			var sql:String = "Select * from messages WHERE userid=" + settings.userId
				+ " AND (";
			for each(var s:String in searchTerms)
				sql += "plainMessage LIKE '%" + s + "%' OR ";
			sql = sql.substr(0, sql.length-4);
			sql += ") ORDER BY " + sortType + " DESC";
			
			var result:SQLResult = execute(sql);
			if(result && result.data)
				return result.data;

			return null;
		}
		
		private function execute(sql:String):SQLResult
		{
			appModel.log("SQL : " + sql);
			var start:int = getTimer();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = sql;
			stmt.execute();
			appModel.log("SQL : QUERY DURATION : " + (getTimer() - start));
			return stmt.getResult();
		}
	}
}