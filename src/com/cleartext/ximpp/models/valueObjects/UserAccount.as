package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.utils.AvatarUtils;
	
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
			"customStatus TEXT, " +
			"avatar TEXT, " + 
			"avatarHash TEXT);";
		
		public function UserAccount()
		{
			// Buddy() requires a jid in the constructor
			super("");
			buddyId = -2;
		}
		
		public var userId:int = -1;
		public var accountName:String = "new account";
		public var password:String;
		public var server:String;
		
		public static function createFromDB(obj:Object):UserAccount
		{
			var newUserAccount:UserAccount = new UserAccount();
			
			newUserAccount.userId = obj["userId"];
			newUserAccount.accountName = obj["accountName"];	
			newUserAccount.jid = obj["jid"];	
			newUserAccount.nickName = obj["nickname"];			
			newUserAccount.password = obj["password"];			
			newUserAccount.server = obj["server"];
			newUserAccount.customStatus = obj["customStatus"];
			newUserAccount.avatarHash = obj["avatarHash"];
			AvatarUtils.stringToAvatar(obj["avatar"], newUserAccount);
			
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
				new DatabaseValue("nickname", nickName),
				new DatabaseValue("password", password),
				new DatabaseValue("server", server),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("avatar", AvatarUtils.avatarToString(avatar))
				];			
		}
		
		override public function toString():String
		{
			return "";
		}
	}
}