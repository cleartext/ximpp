package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.models.MicroBloggingModel;
	import com.cleartext.esm.models.utils.AvatarUtils;
	
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
			"customStatus TEXT, " +
			"avatar TEXT, " + 
			"avatarHash TEXT, " + 
			"mBlogDisplayName TEXT, " + 
			"mBlogPrivateJid BOOLEAN, " + 
			"mBlogUseChatAvatar BOOLEAN, " + 
			"mBlogAvatar TEXT, " + 
			"mBlogAvatarUrl TEXT);";
		
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
		
		public var mBlogDisplayName:String;
		public var mBlogPrivateJid:Boolean;
		public var mBlogUseChatAvatar:Boolean;
		public var mBlogAvatarUrl:String;
		public var mBlogAvatar:BitmapData;
		
		public static function createFromDB(obj:Object, mBlogBuddies:MicroBloggingModel):UserAccount
		{
			var newUserAccount:UserAccount = new UserAccount();
			
			newUserAccount.userId = obj["userId"];
			newUserAccount.accountName = obj["accountName"];	
			newUserAccount.jid = obj["jid"];	
			newUserAccount.nickname = obj["nickname"];			
			newUserAccount.password = obj["password"];			
			newUserAccount.server = obj["server"];
			newUserAccount.customStatus = obj["customStatus"];
			newUserAccount.avatarHash = obj["avatarHash"];
			
			newUserAccount.mBlogDisplayName = obj["mBlogDisplayName"];
			newUserAccount.mBlogPrivateJid = obj["mBlogPrivateJid"];
			newUserAccount.mBlogUseChatAvatar = obj["mBlogUseChatAvatar"];
			newUserAccount.mBlogAvatarUrl = obj["mBlogAvatarUrl"];

			newUserAccount.avatarString = obj["avatar"];
//			AvatarUtils.stringToAvatar(obj["mBlogAvatar"], newUserAccount, "mBlogAvatar");
			
			
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
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("avatar", avatarString),
//				new DatabaseValue("mBlogAvatar", AvatarUtils.avatarToString(mBlogAvatar)),
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