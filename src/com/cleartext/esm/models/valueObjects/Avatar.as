package com.cleartext.esm.models.valueObjects
{
	import com.cleartext.esm.events.AvatarEvent;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import mx.graphics.codec.PNGEncoder;
	import mx.utils.Base64Encoder;

	public class Avatar extends EventDispatcher
	{
		public static const CREATE_AVATARS_TABLE:String =
			"CREATE TABLE IF NOT EXISTS avatars (" +
			"userId INTEGER, " +
			"avatarId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"jid TEXT UNIQUE, " +
			"urlOrHash TEXT, " +
			"bitmapString TEXT, " +
			"userName TEXT, " +
			"displayName TEXT, " +
			"profileUrl TEXT);";
		
		public var avatarId:int = -1;
		public var jid:String;

		private var _urlOrHash:String;
		public function get urlOrHash():String
		{
			return _urlOrHash;
		}
		public function set urlOrHash(value:String):void
		{
			if(urlOrHash != value)
			{
				_urlOrHash = value;
				dispatchEvent(new AvatarEvent(AvatarEvent.SAVE));
			}
		}
		
		private var _displayName:String;
		public function get displayName():String
		{
			return _displayName;
		}
		public function set displayName(value:String):void
		{
			if(displayName != value)
			{
				_displayName = value;
				dispatchEvent(new AvatarEvent(AvatarEvent.SAVE));
				dispatchEvent(new AvatarEvent(AvatarEvent.MBLOG_VALUES_CHANGE));
			}
		}
		
		private var _userName:String;
		public function get userName():String
		{
			return _userName;
		}
		public function set userName(value:String):void
		{
			if(userName != value)
			{
				_userName = value;
				dispatchEvent(new AvatarEvent(AvatarEvent.SAVE));
				dispatchEvent(new AvatarEvent(AvatarEvent.MBLOG_VALUES_CHANGE));
			}
		}
		
		private var _profileUrl:String;
		public function get profileUrl():String
		{
			return _profileUrl;
		}
		public function set profileUrl(value:String):void
		{
			if(profileUrl != value)
			{
				_profileUrl = value;
				dispatchEvent(new AvatarEvent(AvatarEvent.SAVE));
				dispatchEvent(new AvatarEvent(AvatarEvent.MBLOG_VALUES_CHANGE));
			}
		}
		
		public var tempUrlOrHash:String;
		
		private var _bitmapData:BitmapData;
		[Bindable (event="avatarChange")]
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		public function set bitmapData(value:BitmapData):void
		{
			if(bitmapData != value)
			{
				_bitmapData = value;
				if(bitmapData)
				{
					var byteArray:ByteArray = bitmapData.getPixels(new Rectangle(0,0,bitmapData.width, bitmapData.height));
//					var byteArray:ByteArray = new PNGEncoder().encode(bitmapData);
					var base64Enc:Base64Encoder = new Base64Encoder();
					base64Enc.encodeBytes(byteArray);
					bitmapString = base64Enc.flush();
				}
				else
				{
					bitmapString = "";
				}
				dispatchEvent(new AvatarEvent(AvatarEvent.BITMAP_DATA_CHANGE));
			}
		}
		
		private var _bitmapString:String;
		public function get bitmapString():String
		{
			return _bitmapString;
		}
		public function set bitmapString(value:String):void
		{
			if(bitmapString != value)
			{
				_bitmapString = value;
				dispatchEvent(new AvatarEvent(AvatarEvent.SAVE));
			}
		}
		
		public function Avatar()
		{
			super();
		}

		public static function createFromDB(obj:Object, bmd:BitmapData):Avatar
		{
			var avatar:Avatar = new Avatar();
			avatar.avatarId = obj["avatarId"];
			avatar.jid = obj["jid"];
			avatar.urlOrHash = obj["urlOrHash"];
			avatar.bitmapString = obj["bitmapString"];
			avatar.userName = obj["userName"];
			avatar.displayName = obj["displayName"];
			avatar.profileUrl = obj["profileUrl"];
			avatar.bitmapData = bmd;
			return avatar;
		}
		
		//----------------------------------------
		//  CREATE DATABASE VALUES
		//----------------------------------------
		
		public function toDatabaseValues(userId:int):Array
		{
			return [
				new DatabaseValue("userId", userId),
				new DatabaseValue("jid", jid),
				new DatabaseValue("urlOrHash", urlOrHash),
				new DatabaseValue("bitmapString", bitmapString),
				new DatabaseValue("userName", userName),
				new DatabaseValue("displayName", displayName),
				new DatabaseValue("profileUrl", profileUrl)
			];
		}
	}
}