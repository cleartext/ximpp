package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.DatabaseValue;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.MicroBloggingBuddy;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	public class DatabaseModel extends EventDispatcher
	{
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
				appModel.log("Creating and opening database");
				
				// create the local database file
				var dbName:String = "ximpp.db";
				// dbName = "ok-ximpp.db";
				// dbName = new Date().time + ".db";
				
				var dbFile:File = File.applicationStorageDirectory.resolvePath(dbName);
				appModel.log("DB Location: " + dbFile.nativePath);
				
				// link the sync connection to the file
				appModel.log("Opening sync database connection")
				syncConn = new SQLConnection();
				syncConn.open(dbFile, SQLMode.CREATE);
				syncConn.addEventListener(SQLErrorEvent.ERROR, appModel.log, false, 0, true);

				// start a transaction
				syncConn.begin();
				var stmt:SQLStatement = new SQLStatement();
				stmt.sqlConnection = syncConn;
				
				/*
				 * create the global settings table
				 */
				appModel.log("Creating global settings table.");
				stmt.text = GlobalSettings.CREATE_GLOBAL_SETTINGS_TABLE;
				stmt.execute();

				/*
				 * check there is at least one row in the global settings table
				 */
				appModel.log("Checking default global settings exist.");
				stmt.text = "INSERT INTO globalSettings (settingId)" + 
					"SELECT 1 " + 
					"WHERE NOT EXISTS (SELECT 1 FROM globalSettings WHERE settingId=1)";
				stmt.execute();

				/*
				 * create the user accounts table
				 */
				appModel.log("Creating user settings table.");
				stmt.text = UserAccount.CREATE_USER_ACCOUNTS_TABLE;
				stmt.execute();
				
				/*
				 * check there is at least one user account
				 */
				appModel.log("Checking user account exist.");
				stmt.text = "INSERT INTO userAccounts (userId)" + 
					"SELECT 1 " + 
					"WHERE NOT EXISTS (SELECT 1 FROM userAccounts WHERE userId=1)";
				stmt.execute();

				/*
				 * create messages table
				 */
				appModel.log("Creating messages table");
				stmt.text = Message.CREATE_MESSAGES_TABLE;
				stmt.execute();
				
				/*
				 * Create buddy table
				 */
				appModel.log("Creating buddy table");
				stmt.text = Buddy.CREATE_BUDDIES_TABLE;
				stmt.execute();
				
				/*
				 * Create imageCache table
				 */
				appModel.log("Creating microBloggingBuddiesTable table");
				stmt.text = MicroBloggingBuddy.CREATE_MICRO_BLOGGING_BUDDIES_TABLE;
				stmt.execute();
				
				syncConn.commit();
				appModel.log("Database created");
				
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
			// start a transaction 
			syncConn.begin(); 
			appModel.log("Loading user settings");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "SELECT * FROM userAccounts WHERE userId=" + newUserId;
			stmt.execute();
		    
		   	var result:SQLResult = stmt.getResult();

			if (result && result.data)
			{
			    // if we've got to this point without errors, commit the transaction 
			    syncConn.commit();
				appModel.log("User settings loaded ");

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
			// start a transaction 
			syncConn.begin();
			appModel.log("Loading global settings");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "SELECT * FROM globalSettings";
			stmt.execute();
		    
		   	var result:SQLResult = stmt.getResult();
		   	
		   	var newUserId:int;
			if (result && result.data)
			{
				newUserId = result.data[0]["userId"];
				settings.global = GlobalSettings.createFromDB(result.data[0]) as GlobalSettings;
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("Global settings loaded");

			// if the userId has changed, then we want to get all data from the database
			if(newUserId != settings.userId)
			{
				loadUserSettings(newUserId);
			}
		}

		public function loadBuddyData():void
		{
			try
			{
				syncConn.begin(); 
				appModel.log("Loading buddy list");
				
				var stmt:SQLStatement = new SQLStatement();
				stmt.sqlConnection = syncConn;
				stmt.text = "Select * from buddies WHERE userid=" + settings.userId + " ORDER BY lastSeen ASC" ;
				stmt.execute();
			    syncConn.commit(); 
				
				var result:SQLResult = stmt.getResult();
				
				if(result && result.data)
					for(var i:int=result.data.length-1; i>=0; i--)
						buddies.addBuddy(Buddy.createFromDB(result.data[i]));
	
			    // if we've got to this point without errors, commit the transaction 
				appModel.log("Buddy list loaded");
			}
			catch (e:Error)
			{
				appModel.log(e);
			}
		}
				
		public function getAllUserAccounts():ArrayCollection
		{
			// start a transaction 
			syncConn.begin(); 
			appModel.log("Loading user accounts");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "SELECT * FROM userAccounts";
			stmt.execute();
		    
		   	var result:SQLResult = stmt.getResult();
		   	var accounts:ArrayCollection = new ArrayCollection();

			if (result && result.data)
			{
				var len:int = result.data.length;
				for(var i:int=0; i<len; i++)
					accounts.addItem(UserAccount.createFromDB(result.data[i], mBlogBuddies));
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("User accounts loaded");
			return accounts;
		}
		
		public function removeAccount(userId:int):void
		{
			syncConn.begin(); 
			appModel.log("Deleting user account with userId: " + userId);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "DELETE FROM userAccounts WHERE userId = " + userId;
			stmt.execute();

		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("User account deleted");
		}
		
		public function saveGlobalSettings():void
		{
			appModel.log("Saving global settings.");

			var values:Array = settings.global.toDatabaseValues(settings.userId);
			var criteria:Array = [new DatabaseValue("settingId", 1)];
			
			updateStmt("globalSettings", values, criteria);
		}
		
		public function saveUserAccount(userAccount:UserAccount):int
		{
			appModel.log("Saving user account " + userAccount.accountName + " userId: " + userAccount.userId);
			
			var values:Array = userAccount.toDatabaseValues(userAccount.userId);
			var criteria:Array = [new DatabaseValue("userId", userAccount.userId)]
			
			var result:int = updateOrInsert("userAccounts", values, criteria);
			
			if(result != -1)
				userAccount.userId = result;
			
			return result;
		}
		
		public function saveBuddy(buddy:Buddy):int
		{
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY || buddy is UserAccount)
				return -1;
			
			var criteria:Array = [new DatabaseValue("jid", buddy.jid)];
			var id:int = updateOrInsert("buddies", buddy.toDatabaseValues(settings.userId), criteria);
			if(id != -1)
				buddy.buddyId = id;
			return id;
		}

		public function saveMicroBloggingBuddy(buddy:MicroBloggingBuddy):void
		{
			updateStmt("microBloggingBuddies", buddy.toDatabaseValues(), [new DatabaseValue("microBloggingBuddyId", buddy.microBloggingBuddyId)]);
		}

		public function removeBuddy(buddyId:int):void
		{
			syncConn.begin(); 
			appModel.log("Deleting buddy with buddyId: " + buddyId);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "DELETE FROM buddies WHERE buddyId = " + buddyId;
			stmt.execute();

		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("Buddy deleted");
		}
		
		public function saveMessage(message:Message):void
		{
			message.messageId = insertStmt("messages", message.toDatabaseValues(settings.userId));
		}
		
		public function loadMessages(buddy:Buddy):ArrayCollection
		{
			var buddyArray:Array = (buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? buddies.microBloggingBuddies.toArray() : [buddy];
			if(buddyArray.length == 0)
				return new ArrayCollection();;

			var sortType:String = (settings.global.sortByTimestamp) ? "timestamp" : "messageId";

			// start a transaction 
			syncConn.begin(); 
			appModel.log("Loading messages with " + buddy.jid);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			var sql:String = "Select * from messages WHERE userid=" + settings.userId
				+ " AND (";
			
			for each(var b:Buddy in buddyArray)
				sql += "sender='" + b.jid + "' OR recipient='" + b.jid + "' OR ";

			sql = sql.substr(0, sql.length-4);
			sql += ") ORDER BY " + sortType + " DESC "
					+ "LIMIT 0," + 
					((buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY) ? settings.global.numTimelineMessages : settings.global.numChatMessages);
			stmt.text = sql;
			trace(sql);
			stmt.execute();
			var result:SQLResult = stmt.getResult();
		    syncConn.commit(); 

			var messages:ArrayCollection = new ArrayCollection();
			
			if(result && result.data)
			{
				var len:int = result.data.length;
				for(var i:int=0; i<len; i++)
					messages.addItem(Message.createFromDB(result.data[i], mBlogBuddies));
			}
		    // if we've got to this point without errors, commit the transaction 
			appModel.log("Messages loaded");

			var sort:Sort = new Sort();
			sort.fields = [new SortField(sortType, false, true)];
			messages.sort = sort;
			return messages;
		}
		
		private function insertStmt(table:String, values:Array):int
		{
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			
			var sql:String = "INSERT INTO " + table + " (";
			var valuesString:String = ") VALUES (";
			
			var firstTime:Boolean = true;
			for each(var value:DatabaseValue in values)
			{
				if(firstTime)
					firstTime = false;
				else
				{
					sql += ", ";
					valuesString += ", ";
				}

				sql += value.columnName;
				valuesString += value.param;
				stmt.parameters[value.param] = value.value;
			}
			
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
			
			var firstTime:Boolean = true;
			for each(var v:DatabaseValue in values)
			{
				if(firstTime)
					firstTime = false;
				else
					sql += ", ";
				
				sql += v.setParameter(stmt);
			}
			
			firstTime = true;
			for each(var c:DatabaseValue in criteria)
			{
				if(firstTime)
				{
					sql += " WHERE ";
					firstTime = false;
				}
				else
					sql += " AND ";

				sql += c.setParameter(stmt);
			}
			stmt.text = sql;
			stmt.execute();
			syncConn.commit();
		}
		
		private function updateOrInsert(table:String, values:Array, criteria:Array):int
		{
			syncConn.begin();
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			
			var sql:String = "SELECT * FROM " + table;

			var firstTime:Boolean = true;
			for each(var c:DatabaseValue in criteria)
			{
				if(firstTime)
				{
					sql += " WHERE ";
					firstTime = false;
				}
				else
					sql += " AND ";

				sql += c.setParameter(stmt);
			}
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
			syncConn.begin(); 
			appModel.log("Loading microBloggingBuddy: " + idOrUserName);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "Select * from microBloggingBuddies WHERE ";
			
			if(!gatewayJid)
				stmt.text += "microBloggingBuddyId=" + idOrUserName;
			else
				stmt.text += "userName='" + idOrUserName + "' AND gatewayJid='" + gatewayJid + "'";
		
			stmt.execute();
			var result:SQLResult = stmt.getResult();
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 

			if(result && result.data && result.data.length > 0)
				return MicroBloggingBuddy.createFromDB(result.data[0]);
			
			// now we have to create a new buddy
			if(!gatewayJid)
				throw new Error("need a gatewayJid");

			var buddy:MicroBloggingBuddy = new MicroBloggingBuddy();
			buddy.userName = idOrUserName as String;
			buddy.gatewayJid = gatewayJid;
			buddy.microBloggingBuddyId = insertStmt("microBloggingBuddies", buddy.toDatabaseValues());
			
			return buddy;
		}
		
		public function searchMessages(searchTerms:Array):Array
		{
			var sortType:String = (settings.global.sortByTimestamp) ? "timestamp" : "messageId";
			
			// start a transaction 
			syncConn.begin(); 
			appModel.log("Loading messages with searchTerms " + searchTerms.join(", "));
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			var sql:String = "Select * from messages WHERE userid=" + settings.userId
				+ " AND (";
			
			for each(var s:String in searchTerms)
				sql += "plainMessage LIKE '%" + s + "%' OR ";

			sql = sql.substr(0, sql.length-4);
			sql += ") ORDER BY timestamp";
			stmt.text = sql;
			stmt.execute();
			var result:SQLResult = stmt.getResult();
		    syncConn.commit(); 

			if(result && result.data)
				return result.data;
			return null;
		}
	}
}