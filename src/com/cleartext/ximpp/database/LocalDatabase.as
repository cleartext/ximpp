package com.cleartext.ximpp.database
{
	import com.cleartext.ximpp.model.XModel;
	import com.cleartext.ximpp.model.valueObjects.Buddy;
	import com.cleartext.ximpp.model.valueObjects.Message;
	import com.cleartext.ximpp.model.valueObjects.UrlShortener;
	import com.cleartext.ximpp.model.valueObjects.UserAccount;
	
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	
	public class LocalDatabase
	{
		/*
		 * asynchronous and synchronous database connections
		 */
		private var asyncConn:SQLConnection = new SQLConnection();
		private var syncConn:SQLConnection = new SQLConnection();
		
		private var maxNumMessages:int = 500;
		private var numTries:Number = 0;
		
		/*
		 * A shortcut to the model
		 */
		private function get xModel():XModel
		{
			return XModel.getInstance();
		}
				
		public function close():void
		{
			// link the two connections to the file
			xModel.log("Closing async database connection")
			asyncConn.close();

			xModel.log("Closing sync database connection")
			syncConn.close();
		}
		
		/**
		 * create the database file and make sure the appropriate tables exist
		 */
		public function createDatabase():void
		{
			try
			{
				xModel.log("Creating and opening database");
				
				// create the on-disk database
				var dbName:String = "ximpp.db";
//				dbName = new Date().time + ".db";
				
				var dbFile:File = File.applicationStorageDirectory.resolvePath(dbName);
				xModel.log("DB Location: " + dbFile.nativePath);
				
				asyncConn.addEventListener(SQLErrorEvent.ERROR, xModel.log);
				
				// link the two connections to the file
				xModel.log("Openning async database connection")
				asyncConn.openAsync(dbFile);

				xModel.log("Opening sync database connection")
				syncConn.open(dbFile, SQLMode.UPDATE);
	
				// start a transaction
				syncConn.begin();
				var stmt:SQLStatement = new SQLStatement();
				stmt.sqlConnection = syncConn;
				
				/*
				 * create the global settings table
				 */
				xModel.log("Creating global settings table.");
				stmt.text = "CREATE TABLE IF NOT EXISTS globalSettings (" +
					"settingId INTEGER PRIMARY KEY AUTOINCREMENT, " +
					"autoConnect BOOLEAN NOT NULL DEFAULT FALSE, " +
					"urlShortener TEXT, " +
					"timelineTopDown BOOLEAN NOT NULL DEFAULT FALSE, " +
					"chatTopDown BOOLEAN NOT NULL DEFAULT FALSE, " +
					"userId INTEGER);";
				stmt.execute();
				
				/*
				 * check there is at least one row in the global settings table
				 */
				xModel.log("Checking default global settings exist.");
				stmt.text = "INSERT INTO globalSettings (settingId)" + 
					"SELECT 1 " + 
					"WHERE NOT EXISTS (SELECT 1 FROM globalSettings WHERE settingId=1)";
				stmt.execute();

				/*
				 * create the user accounts table
				 */
				xModel.log("Creating user settings table.");
				stmt.text = UserAccount.CREATE_USER_ACCOUNTS_TABLE;
				stmt.execute();
				
				/*
				 * create the messages table
				 */
				xModel.log("Creating messages table");
				stmt.text = Message.CREATE_MESSAGES_TABLE;
				stmt.execute();
				
				/*
				 * Create the message indexes
				 */
				stmt.text = "CREATE INDEX IF NOT EXISTS publisher_idx ON messages(publisher)";
				stmt.execute();
				stmt.text = "CREATE INDEX IF NOT EXISTS subscriber_idx ON messages(subscriber)";
				stmt.execute();
				
				/*
				 * Create entitites table
				 */
				xModel.log("Creating buddy table");
				stmt.text = Buddy.CREATE_BUDDIES_TABLE;
				stmt.execute();
				
				syncConn.commit();
				xModel.log("Database created");
			}
			/**
			 * If there is an error in the initialisation, then try again up to 5 times
			 * before exiting the app.
			 */
			catch (error:Error)
			{
				numTries++;
				xModel.log("Try number: " + numTries + error);
				
				if(numTries < 5)
				{
					createDatabase();
				}
				else
				{
					xModel.fatalError("Could not initialise database.");
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
			xModel.log("Loading user settings");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "SELECT * FROM userAccounts WHERE userId=" + newUserId;
			stmt.execute();
		    
		   	var result:SQLResult = stmt.getResult();

			if (result && result.data)
			{
				var userAccount:UserAccount = new UserAccount();
				userAccount.fill(result.data[0]);
				xModel.userAccount = userAccount;
			}
			else
			{
				xModel.userAccount = null;
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			xModel.log("User settings loaded ");
		}
		
		/**
		 * Load global settings
		 */
		public function loadGlobalSettings():void
		{
			// start a transaction 
			syncConn.begin(); 
			xModel.log("Loading global settings");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "SELECT * FROM globalSettings";
			stmt.execute();
		    
		   	var result:SQLResult = stmt.getResult();
		   	
		   	var newUserId:int;
			if (result && result.data)
			{
				newUserId = result.data[0]["userId"];
				xModel.autoConnect = result.data[0]["autoConnect"];
				xModel.urlShortener = result.data[0]["urlShortener"];
				if(UrlShortener.types.indexOf(xModel.urlShortener) == -1)
				{
					xModel.urlShortener = UrlShortener.types[0];
				} 
				xModel.timelineTopDown = result.data[0]["timelineTopDown"];
				xModel.chatTopDown = result.data[0]["chatTopDown"];
			}
			
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			xModel.log("Global settings loaded");

			// if the userId has changed, then we want to get all data from the database
			if(newUserId != xModel.userId)
			{
				loadUserSettings(newUserId);
				loadBuddyData();
				loadMessageDataNoFilter();
			}
		}

		public function loadBuddyData():void
		{
			if(xModel.userId==-1)
			{
				xModel.log("Can not load buddies: no account selected");
				return;
			}
			
			syncConn.begin(); 
			xModel.log("Loading buddy list");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "Select * from buddies WHERE userid=" + xModel.userId ;
			stmt.execute();
			
			var result:SQLResult = stmt.getResult();
			
			xModel.buddies.removeAll();
			
			if(result && result.data)
			{
				for(var i:Number=result.data.length-1; i>=0; i--)
				{
					var buddy:Buddy = new Buddy();
					buddy.fill(result.data[i]);
					xModel.buddies.addItem(buddy);
				}
			}
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			xModel.log("Buddy list loaded");
		}
		
		public function loadMessageDataNoFilter():void
		{
			if(xModel.userId==-1)
			{
				xModel.log("Can not load messages: no account selected");
				return;
			}
			
			syncConn.begin(); 
			xModel.log("Loading message data");
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "Select * from messages WHERE userid=" + xModel.userId
				+ " ORDER BY timestamp DESC LIMIT 0," + maxNumMessages;
			stmt.execute();
			
			var result:SQLResult = stmt.getResult();
			
			xModel.messages.removeAll();
			
			if(result && result.data)
			{
				var len:int = Math.min(result.data.length, maxNumMessages);
				for(var i:int=0; i<len; i++)
				{
					var message:Message = new Message();
					message.fill(result.data[i]);
					xModel.messages.addItem(message);
				}
			}
		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			xModel.log("Message data loaded");
		}
		
		public function getAllUserAccounts():ArrayCollection
		{
			// start a transaction 
			syncConn.begin(); 
			xModel.log("Loading user accounts");
			
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
			xModel.log("User accounts loaded");
			return accounts;
		}
		
		public function removeAccount(userId:int):void
		{
			syncConn.begin(); 
			xModel.log("Deleting user account with userId: " + userId);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = syncConn;
			stmt.text = "DELETE FROM userAccounts WHERE userId = " + userId;
			stmt.execute();

		    // if we've got to this point without errors, commit the transaction 
		    syncConn.commit(); 
			xModel.log("User account deleted");
		}
		
		public function saveGlobalSettings():void
		{
			xModel.log("Saving global settings.");

			var values:Array = 
				[new DatabaseValue("autoConnect", xModel.autoConnect),
				new DatabaseValue("urlShortener", xModel.urlShortener),
				new DatabaseValue("timelineTopDown", xModel.timelineTopDown),
				new DatabaseValue("chatTopDown", xModel.chatTopDown),
				new DatabaseValue("userId", xModel.userId)];
			var criteria:Array =
				[new DatabaseValue("settingId", 1)];

			updateStmt("globalSettings", values, criteria);
		}
		
		public function saveUserAccount(userAccount:UserAccount, update:Boolean=true):int
		{
			xModel.log("Saving user account " + userAccount.accountName + " userId: " + userAccount.userId);
			
			var values:Array = userAccount.databaseValues;
			var criteria:Array = [new DatabaseValue("userId", userAccount.userId)]
			
			if(update)
			{	
				updateStmt("userAccounts", values, criteria);
				return -1;
			}
			return insertStmt("userAccounts", values);
		}
		
		public function saveBuddy(buddy:Buddy):int
		{
			var criteria:Array = [new DatabaseValue("jid", buddy.jid)];
			return updateOrInsert("buddies", buddy.databaseValues, criteria);
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