package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.XimppUtils;
	
	import flash.display.BitmapData;
	
	public class UserAccount extends Buddy implements IXimppValueObject
	{
		public static const CREATE_USER_ACCOUNTS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS userAccounts (" +
			"userId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"accountName TEXT DEFAULT 'default account', " +
			"timestamp DATE, " +
			"jid TEXT, " +
			"nickname TEXT, " +
			"password TEXT, " +
			"server TEXT, " +
			"customStatus TEXT, " +
			"avatar TEXT);";
		
		public function UserAccount()
		{
			super();
			buddyId = -2;
		}
		
		public var userId:int = -1;
		public var accountName:String = "new account";
		public var password:String;
		public var server:String;
		
		public static function createFromDB(obj:Object):IXimppValueObject
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

			XimppUtils.stringToAvatar(obj["avatar"], newUserAccount);
			
			return newUserAccount;
		}
		
		public function get valid():Boolean
		{
			return (jid && password && password);
		}
		
		override public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("accountName", accountName),
				new DatabaseValue("timestamp", new Date()),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", nickName),
				new DatabaseValue("password", password),
				new DatabaseValue("server", server),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar))
				];			
		}
		
		override public function toString():String
		{
			return "";
		}
	}
}