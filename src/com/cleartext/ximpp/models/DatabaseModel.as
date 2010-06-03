package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.events.LoadingEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.BuddyRequest;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.DatabaseValue;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.MicroBloggingBuddy;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
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
		private var maxTimeForProcess:int = 10;
		private var timeout:int = 10;
		
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
				
		public function close():void
		{
			appModel.log("Closing sync database connection")
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
				syncConn.open(dbFile, SQLMode.CREATE);
				syncConn.addEventListener(SQLErrorEvent.ERROR, appModel.log, false, 0, true);

				var sql:String;
				
				/*
				 * create the global settings table
				 */
				appModel.log("Creating global settings table", true);
				execute(GlobalSettings.CREATE_GLOBAL_SETTINGS_TABLE);

				/*
				 * check there is at least one row in the global settings table
				 */
				appModel.log("Checking default global settings exist");
				execute("INSERT INTO globalSettings (settingId)" + 
					"SELECT 1 " + 
					"WHERE NOT EXISTS (SELECT 1 FROM globalSettings WHERE settingId=1)");

				/*
				 * create the user accounts table
				 */
				appModel.log("Creating user settings table", true);
				execute(UserAccount.CREATE_USER_ACCOUNTS_TABLE);
				
				/*
				 * check there is at least one user account
				 */
				appModel.log("Checking user account exist");
				execute("INSERT INTO userAccounts (userId)" + 
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
				 * Create microBloggingBuddies table
				 */
				appModel.log("Creating microBloggingBuddiesTable table", true);
				execute(MicroBloggingBuddy.CREATE_MICRO_BLOGGING_BUDDIES_TABLE);

				/*
				 * Create buddyRequests table
				 */
				appModel.log("Creating buddyRequests table", true);
				execute(BuddyRequest.CREATE_BUDDY_REQUESTS_TABLE);
				
				var mods:Array;
				var column:SQLColumnSchema;
				var mod:Object;
				var i:int;
				
				syncConn.loadSchema();
				var schema:SQLSchemaResult = syncConn.getSchemaResult();
				for each (var table:SQLTableSchema in schema.tables)
				{
					if(table.name == "buddies")
					{
						mods = Buddy.TABLE_MODS.slice();
						
						for each(column in table.columns)
						{
							for(i=0; i<mods.length; i++)
							{
								if(column.name == mods[i].name)
									mods.splice(i,1);
							}
						}
						
						for each(mod in mods)
						{
							sql = "ALTER TABLE buddies ADD COLUMN " + mod.name + " " + mod.type;
							if(mod.hasOwnProperty("defaultVal"))
								sql += " DEFAULT " + mod.defaultVal;
							appModel.log("Updating buddy table structure", true);
							execute(sql);
						}
					}
					else if(table.name == "messages")
					{
						mods = Message.TABLE_MODS.slice();
						
						for each(column in table.columns)
						{
							for(i=0; i<mods.length; i++)
							{
								if(column.name == mods[i].name)
									mods.splice(i,1);
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
						
						appModel.log("Setting receivedTimestamp feild", true);
						sql = "UPDATE messages SET receivedTimestamp=strftime('%s',timestamp)*1000 WHERE receivedTimestamp is null";
						execute(sql);
						
						appModel.log("Setting sentTimestamp feild", true);
						sql = "UPDATE messages SET sentTimestamp=strftime('%s',timestamp)*1000 WHERE sentTimestamp is null";
						execute(sql);
					}
				}
				appModel.log("Database successfully created", true);
			}
			catch (error:Error)
			{
				appModel.log(error);
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
			{
				settings.userAccount = UserAccount.createFromDB(result.data[0], mBlogBuddies);
			}
			else
			{
				appModel.fatalError("no user account with id: " + newUserId);
			}
		}
		
		/**
		 * Load global settings
		 */
		public function loadGlobalSettings():void
		{
			appModel.log("Loading global settings", true);
		    var result:SQLResult = execute("SELECT * FROM globalSettings");
		   	
		   	var newUserId:int;
			if (result && result.data)
			{
				newUserId = result.data[0]["userId"];
				settings.global = GlobalSettings.createFromDB(result.data[0]) as GlobalSettings;
			}
			
			// if the userId has changed, then we want to get all data from the database
			if(newUserId != settings.userId)
			{
				loadUserSettings(newUserId);
			}
		}

		public function loadBuddyData(data:Array=null, index:int=0):void
		{
			var start:int = getTimer();
			
			if(data)
			{
				while(index>=0)
				{
					buddies.addBuddy(Buddy.createFromDB(data[index]));
					index--;
					if(start + maxTimeForProcess < getTimer())
					{
						var len:int = data.length;
						dispatchEvent(new LoadingEvent(LoadingEvent.BUDDIES_LOADING, len-index, len));
						setTimeout(loadBuddyData, timeout, data, index);
						return;
					}
				}
				
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
					var result:SQLResult = execute("Select * from buddies WHERE userid=" + settings.userId + " ORDER BY lastSeen DESC");
					
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
					accounts.addItem(UserAccount.createFromDB(result.data[i], mBlogBuddies));
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

			var values:Array = settings.global.toDatabaseValues(settings.userId);
			var criteria:Array = [new DatabaseValue("settingId", 1)];
			
			updateStmt("globalSettings", values, criteria);
		}
		
		public function saveUserAccount(userAccount:UserAccount):int
		{
			appModel.log("Saving user account : " + userAccount.accountName + " userId: " + userAccount.userId, true);
			
			var values:Array = userAccount.toDatabaseValues(userAccount.userId);
			var criteria:Array = [new DatabaseValue("userId", userAccount.userId)]
			
			var result:int = updateOrInsert("userAccounts", values, criteria);
			
			if(result != -1)
				userAccount.userId = result;
			
			return result;
		}
		
		public function saveBuddy(buddy:Buddy):int
		{
			appModel.log("Saving buddy : " + buddy.jid + " buddyId: " + buddy.buddyId, true);
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY || buddy is UserAccount)
				return -1;
			
			var criteria:Array = [new DatabaseValue("jid", buddy.jid)];
			var id:int = updateOrInsert("buddies", buddy.toDatabaseValues(settings.userId), criteria);
			if(id != -1)
				buddy.buddyId = id;
			return id;
		}

		public function saveRequest(request:BuddyRequest):int
		{
			appModel.log("Saving buddy request : " + request.jid + " incoming: " + request.incomming, true);
			var criteria:Array = [new DatabaseValue("jid", request.jid)];
			var id:int = updateOrInsert("buddyRequests", request.toDatabaseValues(settings.userId), criteria);
			if(id != -1)
				request.buddyRequestId = id;
			return id;
		}

		public function saveMicroBloggingBuddy(buddy:MicroBloggingBuddy):void
		{
			appModel.log("Saving microblogging buddy : "  + buddy.jid + " micoBloggingBuddyId: " + buddy.microBloggingBuddyId, true);
			updateStmt("microBloggingBuddies", buddy.toDatabaseValues(), [new DatabaseValue("microBloggingBuddyId", buddy.microBloggingBuddyId)]);
		}

		public function removeBuddy(buddy:Buddy):void
		{
			appModel.log("Deleting buddy : " + buddy.jid + " buddyId: " + buddy.buddyId, true);
			execute("DELETE FROM buddies WHERE buddyId = " + buddy.buddyId);
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
				chats.getChat(chatsToOpen[index] as Buddy);
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
			var buddy:Buddy = chat.buddy;
			var buddyArray:Array = (buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? buddies.microBloggingBuddies.toArray() : [buddy];
			if(buddyArray.length == 0)
			{
				if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADED));
				return;
			}

			appModel.log("Loading messages with " + chat.buddy.jid, true);
			var sql:String = "Select * from messages WHERE userid=" + settings.userId + " AND (";
			
			for each(var b:Buddy in buddyArray)
			{
				sql += "sender='" + b.jid + "' OR recipient='" + b.jid + "' OR ";
			}

			sql = sql.substr(0, sql.length-4);
			sql += ") ORDER BY " + 
					((settings.global.sortBySentDate) ? "sentTimestamp" : "receivedTimestamp") + 
					" DESC LIMIT 0," + 
					((buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? settings.global.numTimelineMessages : settings.global.numChatMessages);
			
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
						chat.messages.addItem(Message.createFromDB(result.data[i], mBlogBuddies));
					}
					dispatchEvent(new LoadingEvent(LoadingEvent.CHAT_LOADED));
				}
				else
				{
					loopOverMessages(result.data, 0, chat);
				}
			}
			else if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
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
				chat.messages.addItem(Message.createFromDB(data[index], mBlogBuddies));
				index++;
				if(start + maxTimeForProcess < getTimer())
				{
					if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
					{
						dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADING, index-1, len));
					}
					setTimeout(loopOverMessages, timeout, data, index, chat);
					return;
				}
			}
			
			if(chat.buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
			{
				dispatchEvent(new LoadingEvent(LoadingEvent.WORKSTREAM_LOADED));
			}
		}
		
		private function insertStmt(table:String, values:Array):int
		{
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
			
			return stmt.getResult().lastInsertRowID;
		}
		
		private function updateStmt(table:String, values:Array, criteria:Array):void
		{
			if(!table || !values)
				return;
			
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
		}
		
		private function updateOrInsert(table:String, values:Array, criteria:Array):int
		{
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			
			var sql:String = "SELECT * FROM " + table;
			var renderedSql:String = "SQL : " + sql;
			var firstTime:Boolean = true;
			for each(var c:DatabaseValue in criteria)
			{
				if(firstTime)
				{
					sql += " WHERE ";
					renderedSql += " WHERE ";
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
			
			appModel.log(renderedSql);
			stmt.text = sql;
			stmt.execute();
			var result:SQLResult = stmt.getResult();
			syncConn.commit();
			
			if(result && result.data)
			{
				updateStmt(table, values, criteria);
				return -1;
			}
			else
			{
				return insertStmt(table, values);
			}
		}
		
		public function getMicroBloggingBuddy(idOrUserName:Object, gatewayJid:String=null):MicroBloggingBuddy
		{
			var traceStr:String = idOrUserName + (gatewayJid ? ("@" + gatewayJid) : "");
			var sql:String = "Select * from microBloggingBuddies WHERE ";
			
			if(!gatewayJid)
				sql += "microBloggingBuddyId=" + idOrUserName;
			else
				sql += "userName='" + idOrUserName + "' AND gatewayJid='" + gatewayJid + "'";
		
			appModel.log("Loading microBloggingBuddy : " + traceStr, true);
			var result:SQLResult = execute(sql);

			if(result && result.data && result.data.length > 0)
				return MicroBloggingBuddy.createFromDB(result.data[0]);
			
			// now we have to create a new buddy
			if(!gatewayJid)
				throw new Error("need a gatewayJid");

			var buddy:MicroBloggingBuddy = new MicroBloggingBuddy();
			buddy.userName = idOrUserName as String;
			buddy.gatewayJid = gatewayJid;

			appModel.log("Creating new microBloggingBuddy : " + traceStr, true);
			buddy.microBloggingBuddyId = insertStmt("microBloggingBuddies", buddy.toDatabaseValues());
			
			return buddy;
		}
		
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
			sql += ") ORDER BY " + sortType;
			
			var result:SQLResult = execute(sql);
			if(result && result.data)
				return result.data;

			return null;
		}
		
		private function execute(sql:String):SQLResult
		{
			appModel.log("SQL : " + sql);
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = sql;
			stmt.execute();
			syncConn.commit();
			return stmt.getResult();
		}
	}
}