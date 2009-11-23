package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.models.XimppUtils;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	
	public class UserAccount extends EventDispatcher implements IXimppValueObject
	{
		public static const CREATE_USER_ACCOUNTS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS userAccounts (" +
			"userId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"accountName TEXT DEFAULT 'new account', " +
			"timestamp DATE, " +
			"jid TEXT, " +
			"nickname TEXT, " +
			"password TEXT, " +
			"server TEXT, " +
			"customStatus TEXT, " +
			"avatar TEXT);";
		
		public var userId:int = -1;
		public var accountName:String;
		public var jid:String;
		public var nickname:String;
		public var password:String;
		public var server:String;
		[Bindable]
		public var customStatus:String;
		[Bindable]
		public var avatar:BitmapData;
		
		public function fill(obj:Object):void
		{
			userId = obj["userId"];
			accountName = obj["accountName"];	
			jid = obj["jid"];	
			nickname = obj["nickname"];			
			password = obj["password"];			
			server = obj["server"];
			customStatus = obj["customStatus"];
			avatar = XimppUtils.stringToAvatar(obj["avatar"]);
		}
		
		public function get valid():Boolean
		{
			return (jid && password && password);
		}
		
		public function toBuddy():Buddy
		{
			var buddy:Buddy = new Buddy();
			buddy.jid = jid;
			buddy.nickName = nickname;
			buddy.avatar = avatar;
			buddy.customStatus = customStatus;
			return buddy;
		}
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("accountName", accountName),
				new DatabaseValue("timestamp", new Date()),
				new DatabaseValue("jid", jid),
				new DatabaseValue("nickname", nickname),
				new DatabaseValue("password", password),
				new DatabaseValue("server", server),
				new DatabaseValue("customStatus", customStatus),
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar))];			
		}
		
		override public function toString():String
		{
			return "";
		}
		
		public function toXML():XML
		{
			return null;
		}
	}
}