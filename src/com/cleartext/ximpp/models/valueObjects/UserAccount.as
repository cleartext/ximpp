package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.XimppUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	public class UserAccount extends Buddy implements IXimppValueObject
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
		
		public function UserAccount()
		{
			super();
			buddyId = -2;
		}
		
		public var userId:int = -1;
		public var accountName:String;
		public var nickname:String;
		public var password:String;
		public var server:String;
		
		override public function fill(obj:Object):void
		{
			userId = obj["userId"];
			accountName = obj["accountName"];	
			jid = obj["jid"];	
			nickname = obj["nickname"];			
			password = obj["password"];			
			server = obj["server"];
			customStatus = obj["customStatus"];
			if(obj["avatar"] is String)
				XimppUtils.stringToAvatar(obj["avatar"],
					function(event:Event):void
					{
						avatar = Bitmap(event.target.content).bitmapData;
					});
			else if(obj["avatar"] is BitmapData)
				avatar = obj["avatar"];
		}
		
		public function get valid():Boolean
		{
			return (jid && password && password);
		}
		
		override public function toDatabaseValues(userId:int):Array
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
				new DatabaseValue("avatar", XimppUtils.avatarToString(avatar))
				];			
		}
		
		override public function toString():String
		{
			return "";
		}
		
		override public function toXML():XML
		{
			return null;
		}
	}
}