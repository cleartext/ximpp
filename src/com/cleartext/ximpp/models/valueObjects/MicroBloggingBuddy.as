package com.cleartext.ximpp.models.valueObjects
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.utils.AvatarUtils;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Matrix;
	
	import mx.controls.Image;
	
	public class MicroBloggingBuddy extends EventDispatcher implements IBuddy
	{
		[Autowire]
		public var xmpp:XMPPModel;
		
		public static const CREATE_MICRO_BLOGGING_BUDDIES_TABLE:String =
			"CREATE TABLE IF NOT EXISTS microBloggingBuddies (" +
			"microBloggingBuddyId INTEGER PRIMARY KEY AUTOINCREMENT, " +
			"diplayName TEXT, " +
			"userName TEXT, " +
			"jid TEXT, " + 
			"avatarUrl TEXT, " +
			"avatarHash TEXT, " +
			"avatar TEXT, " +
			"gatewayJid TEXT);";
		
		public var microBloggingBuddyId:int = -1;
		public var userName:String;
		public var gatewayJid:String;

		private var _displayName:String;
		public function get displayName():String
		{
			return _displayName;
		}
		public function set displayName(value:String):void
		{
			if(_displayName != value)
			{
				_displayName = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}
		
		public var avatarUrl:String;
		public var avatarHash:String;
		
		private var _avatar:BitmapData;
		[Bindable (event="buddyChanged")]
		public function get avatar():BitmapData
		{
			return _avatar;
		}
		public function set avatar(value:BitmapData):void
		{
			if(_avatar != value)
			{
				_avatar = value;
				dispatchEvent(new BuddyEvent(BuddyEvent.CHANGED));
			}
		}

		[Bindable (event="buddyChanged")]
		public function get nickName():String
		{
			return displayName + " (@" + userName + ")";
		}
		
		private var _jid:String;
		public function get jid():String
		{
			return (_jid) ? _jid : userName + "@" + gatewayJid;
		}
		public function set jid(value:String):void
		{
			if(_jid != value)
			{
				_jid = value;
			}
		}
		
		public function MicroBloggingBuddy()
		{
			super();
		}
		
		private function imageCompleteHandler(event:Event):void
		{
			var avatarSize:Number = 48;
			
			var image:Image = event.target as Image;
			var bitmap:Bitmap = Bitmap(image.content);
			image.removeEventListener(Event.COMPLETE, imageCompleteHandler);
			
			// if the bitmap is smaller than the AVATAR_SIZE, then scale it down
			// otherwise, just draw at the size we got it
			var scale:Number = avatarSize / Math.max(bitmap.width, bitmap.height, avatarSize);
			var matrix:Matrix = new Matrix(scale, 0, 0, scale);

			var bmd:BitmapData = new BitmapData(Math.min(bitmap.width*scale, avatarSize), Math.min(bitmap.height*scale, avatarSize));
			bmd.draw(bitmap, matrix);
			
			avatar = bmd;
		}

		public function setAvatarUrl(url:String):void
		{
			if(avatarUrl != url || (!avatar && url))
			{
				avatarUrl = url;
				avatar = null;
				var image:Image = new Image();
				image.addEventListener(Event.COMPLETE, imageCompleteHandler);
				image.load(avatarUrl);
			}
		}
		
		public function setJidAndHash(newJid:String, hash:String):void
		{
			jid = newJid;

			if(avatarHash != hash || (!avatar && hash && jid))
			{
				avatarHash = hash;
				avatar = null;
				xmpp.getAvatarForMBlogBuddy(jid);
			}
		}
		
		public static function createFromDB(obj:Object):MicroBloggingBuddy
		{
			var newMicroBloggingBuddy:MicroBloggingBuddy = new MicroBloggingBuddy();
			
			newMicroBloggingBuddy.microBloggingBuddyId = obj["microBloggingBuddyId"];
			newMicroBloggingBuddy.displayName = obj["displayName"];
			newMicroBloggingBuddy.userName = obj["userName"];
			newMicroBloggingBuddy.jid = obj["jid"];
			newMicroBloggingBuddy.avatarUrl = obj["avatarUrl"];
			newMicroBloggingBuddy.avatarHash = obj["avatarHash"];
			newMicroBloggingBuddy.gatewayJid = obj["gatewayJid"];
			AvatarUtils.stringToAvatar(obj["avatar"], newMicroBloggingBuddy);
			
			return newMicroBloggingBuddy;
		}
		
		public function toDatabaseValues():Array
		{
			return [
				new DatabaseValue("displayName", displayName),
				new DatabaseValue("userName", userName),
				new DatabaseValue("jid", jid),
				new DatabaseValue("avatarUrl", avatarUrl),
				new DatabaseValue("avatarHash", avatarHash),
				new DatabaseValue("avatar", AvatarUtils.avatarToString(avatar)),
				new DatabaseValue("gatewayJid", gatewayJid)
				];
		}

	}
}