package com.cleartext.ximpp.models.valueObjects
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class UserAccount extends EventDispatcher implements IXimppValueObject
	{
		public static const CREATE_USER_ACCOUNTS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS userAccounts (" +
			"userId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"accountName TEXT, " +
			"timestamp DATE, " +
			"jid TEXT, " +
			"nickname TEXT, " +
			"password TEXT, " +
			"server TEXT, " +
			"customStatus TEXT, " +
			"avatar TEXT);";
		
		public var userId:int = -1;
		public var accountName:String = "new account";
		public var jid:String = "";
		public var nickname:String = "";
		public var password:String = "";
		public var server:String = "";
		[Bindable]
		public var customStatus:String = "";
		
		[Bindable]
		public var avatar:BitmapData;
		
//		private var _avatarBitmap:Bitmap;
//		public function get avatarBitmap():Bitmap
//		{
//			return new Bitmap(_avatarBitmap.bitmapData);
//		}
//		public function set avatarBitmap(value:Bitmap):void
//		{
//			_avatarBitmap = (value) ? new Bitmap(value.bitmapData) : null;
//		}
		
		public function fill(obj:Object):void
		{
			userId = obj["userId"];
			accountName = obj["accountName"];	
			jid = obj["jid"];	
			nickname = obj["nickname"];			
			password = obj["password"];			
			server = obj["server"];
			customStatus = obj["customStatus"];
			avatar = null;

			var byteString:String = obj["avatar"];
			if(byteString)
			{
				var base64Dec:Base64Decoder = new Base64Decoder();
				base64Dec.decode(byteString);
				var byteArray:ByteArray = base64Dec.toByteArray();

				avatar = new BitmapData(64,64);
				avatar.setPixels(new Rectangle(0,0,64,64), byteArray);
			}
		}
		
		public function get avatarStr():String
		{
			if(avatar)
			{
				var byteArray:ByteArray = avatar.getPixels(new Rectangle(0,0,64,64));
				var base64Enc:Base64Encoder = new Base64Encoder();
				base64Enc.encodeBytes(byteArray);
				var result:String = base64Enc.flush();
				//trace(result);
				return result;
			}
			else
			{
				return null;
			}
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
				new DatabaseValue("avatar", avatarStr)];			
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