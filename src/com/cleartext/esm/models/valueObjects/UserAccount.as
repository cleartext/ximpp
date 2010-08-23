package com.cleartext.esm.models.valueObjects
{
	import flash.display.BitmapData;
	
	public class UserAccount extends Buddy
	{
		public static const CREATE_USER_ACCOUNTS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS userAccounts (" +
			"userId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"accountName TEXT DEFAULT 'default account', " +
			"jid TEXT, " +
			"nickname TEXT, " +
			"password TEXT, " +
			"server TEXT, " +
			"port INTEGER, " +
			"customStatus TEXT, " +
			"avatar TEXT, " + 
			"avatarHash TEXT, " + 
			"mBlogDisplayName TEXT, " + 
			"mBlogPrivateJid BOOLEAN, " + 
			"mBlogUseChatAvatar BOOLEAN, " + 
			"mBlogAvatar TEXT, " + 
			"mBlogAvatarUrl TEXT);";

		public static const TABLE_MODS:Array = [
			{name: "port", type: "INTEGER"}
		];
		
		public function UserAccount()
		{
			super("");
			buddyId = -2;
		}
		
		public var userId:int = -1;
		public var accountName:String = "new account";
		public var password:String;
		public var server:String;
		public var port:uint;
		
		public var mBlogDisplayName:String;
		public var mBlogPrivateJid:Boolean;
		public var mBlogUseChatAvatar:Boolean;
		public var mBlogAvatarUrl:String;
		public var mBlogAvatar:BitmapData;
		
		public static function createFromDB(obj:Object):UserAccount
		{
			var newUserAccount:UserAccount = new UserAccount();
			
			newUserAccount.jid = obj["jid"];
			newUserAccount.userId = obj["userId"];
			newUserAccount.accountName = obj["accountName"];	
			newUserAccount.nickname = obj["nickname"];			
			newUserAccount.password = obj["password"];			
			newUserAccount.server = obj["server"];
			newUserAccount.port = obj["port"]==null ? 5222 : obj["port"];
			newUserAccount.customStatus = obj["customStatus"];
			
			newUserAccount.mBlogDisplayName = obj["mBlogDisplayName"];
			newUserAccount.mBlogPrivateJid = obj["mBlogPrivateJid"];
			newUserAccount.mBlogUseChatAvatar = obj["mBlogUseChatAvatar"];
			newUserAccount.mBlogAvatarUrl = obj["mBlogAvatarUrl"];
			
			return newUserAccount;
		}
		
		public function get valid():Boolean
		{
			return (jid && password && server);
		}
		
		override public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("accountName", accountName),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", nickname),
				new DatabaseValue("password", password),
				new DatabaseValue("server", server),
				new DatabaseValue("port", port),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("mBlogUseChatAvatar", mBlogUseChatAvatar),
				new DatabaseValue("mBlogPrivateJid", mBlogPrivateJid),
				new DatabaseValue("mBlogAvatarUrl", mBlogAvatarUrl),
				new DatabaseValue("mBlogDisplayName", mBlogDisplayName)
				];			
		}
		
		override public function toString():String
		{
			return "";
		}
	}
}