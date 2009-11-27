package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.DatabaseValue;
	import com.cleartext.ximpp.models.valueObjects.GlobalSettings;
	import com.cleartext.ximpp.models.valueObjects.Message;
	import com.cleartext.ximpp.models.valueObjects.UserAccount;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	
	public class DatabaseModel
	{
		/*
		 * asynchronous and synchronous database connections
		 */
		private var asyncConn:SQLConnection = new SQLConnection();
		private var syncConn:SQLConnection = new SQLConnection();
		
		private var numTries:Number = 0;
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel; 
		
		private function get settings():SettingsModel
		{
			return appModel.settings;
		}
				
		public function close():void
		{
			// link the two connections to the file
			appModel.log("Closing async database connection")
			asyncConn.close();

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
				
				// create the on-disk database
				var dbName:String = "ximpp.db";
				//dbName = new Date().time + ".db";
				
				var dbFile:File = File.applicationStorageDirectory.resolvePath(dbName);
				appModel.log("DB Location: " + dbFile.nativePath);
				
				asyncConn.addEventListener(SQLErrorEvent.ERROR, appModel.log);
				
				// link the two connections to the file
				appModel.log("Openning async database connection")
				asyncConn.openAsync(dbFile);

				appModel.log("Opening sync database connection")
				syncConn.open(dbFile, SQLMode.UPDATE);
	
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
				 * create the messages table
				 */
				appModel.log("Creating messages table");
				stmt.text = Message.CREATE_MESSAGES_TABLE;
				stmt.execute();
				
				/*
				 * Create entitites table
				 */
				appModel.log("Creating buddy table");
				stmt.text = Buddy.CREATE_BUDDIES_TABLE;
				stmt.execute();
				
				syncConn.commit();
				appModel.log("Database created");
			}
			/**
			 * If there is an error in the initialisation, then try again up to 5 times
			 * before exiting the app.
			 */
			catch (error:Error)
			{
				numTries++;
				appModel.log("Try number: " + numTries + error);
				
				if(numTries < 15)
				{
					createDatabase();
				}
				else
				{
					appModel.fatalError("Could not initialise database.");
				}
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
				var userAccount:UserAccount = new UserAccount();
				userAccount.fill(result.data[0]);
				settings.userAccount = userAccount;
			}
			else
			{
				settings.userAccount = null;
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("User settings loaded ");
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
				settings.global.fill(result.data[0]);
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("Global settings loaded");

			// if the userId has changed, then we want to get all data from the database
			if(newUserId != settings.userId)
			{
				loadUserSettings(newUserId);
				loadBuddyData();
				loadTimelineData();
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
				stmt.text = "Select * from buddies WHERE userid=" + settings.userId ;
				stmt.execute();
			    syncConn.commit(); 
				
				var result:SQLResult = stmt.getResult();
				
				if(result && result.data)
				{
					for(var i:Number=result.data.length-1; i>=0; i--)
					{
						var buddy:Buddy = new Buddy();
						buddy.fill(result.data[i]);
						appModel.addBuddy(buddy);
					}
				}
			    // if we've got to this point without errors, commit the transaction 
				appModel.log("Buddy list loaded");
			}
			catch (e:Error)
			{
				appModel.log(e);
			}
		}
		
		public function loadTimelineData():void
		{			
			syncConn.begin(); 
			appModel.log("Loading message data");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "Select * from messages WHERE userid=" + settings.userId
				+ " ORDER BY timestamp DESC LIMIT 0," + settings.global.numTimelineMessages;
			stmt.execute();
		    syncConn.commit(); 
			
			var result:SQLResult = stmt.getResult();
			
			appModel.timeLineMessages.removeAll();
			
			if(result && result.data)
			{
				var len:int = result.data.length;
				for(var i:int=0; i<len; i++)
				{
					var message:Message = new Message();
					message.fill(result.data[i]);
					appModel.timeLineMessages.addItem(message);
				}
			}
		    // if we've got to this point without errors, commit the transaction 
			appModel.log("Message data loaded");
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
				{
					var userAccount:UserAccount = new UserAccount();
					userAccount.fill(result.data[i]);
					accounts.addItem(userAccount);
				}
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
			
			if(settings.global.autoConnect && !appModel.xmpp.connected)
				appModel.xmpp.connect();
		}
		
		public function saveUserAccount(userAccount:UserAccount):int
		{
			appModel.log("Saving user account " + userAccount.accountName + " userId: " + userAccount.userId);
			
			var values:Array = userAccount.toDatabaseValues(userAccount.userId);
			var criteria:Array = [new DatabaseValue("userId", userAccount.userId)]
			
			var result:int = updateOrInsert("userAccounts", values, criteria);
			
			return (result==0) ? -1 : result;
		}
		
		public function saveBuddy(buddy:Buddy):int
		{
			var criteria:Array = [new DatabaseValue("jid", buddy.jid)];
			return updateOrInsert("buddies", buddy.toDatabaseValues(settings.userId), criteria);
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
			// start a transaction 
			syncConn.begin(); 
			appModel.log("Loading messages with " + buddy.jid);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "Select * from messages WHERE userid=" + settings.userId
				+ " AND (sender='" + buddy.jid + "'"
				+ " OR recipient='" + buddy.jid + "')"
				+ " ORDER BY timestamp LIMIT 0," + settings.global.numChatMessages;
			stmt.execute();
			
			var result:SQLResult = stmt.getResult();

			var messages:ArrayCollection = new ArrayCollection();
			
			if(result && result.data)
			{
				var len:int = result.data.length;
				for(var i:int=0; i<len; i++)
				{
					var message:Message = new Message();
					message.fill(result.data[i]);
					messages.addItem(message);
				}
			}
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			appModel.log("Messages loaded");
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
	}
	
}