package com.cleartext.esm.models
{
	import com.cleartext.esm.events.AvatarEvent;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.views.common.AvatarRenderer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Image;
	import mx.utils.Base64Decoder;

	public class AvatarModel
	{
		[Autowire]
		public var databaseModel:DatabaseModel;
		
		[Autowire]
		public var xmpp:XMPPModel;
		
		[Autowire]
		public var appModel:ApplicationModel;
		
		public static const AVATAR_SIZE:int = 48;

		private var avatarCache:Dictionary = new Dictionary();
		
		[Bindable]
		public var userAccountAvatar:Avatar;
		
		//--------------------------------
		// constructor
		//--------------------------------
		
		public function AvatarModel()
		{
			userAccountAvatar = new Avatar();
			avatarCache["userAccount"] = userAccountAvatar;
		}
		
		//--------------------------------
		// setUrlOrHash
		//--------------------------------
		
		public function setUrlOrHash(jid:String, urlOrHash:String):void
		{
			if(!urlOrHash)
				return;
			
			var avatar:Avatar = getAvatar(jid);
			if(avatar.urlOrHash != urlOrHash && avatar.tempUrlOrHash != urlOrHash)
			{
				avatar.tempUrlOrHash = urlOrHash;
				
				if(urlOrHash.search('http://')==0)
				{
					var image:Image = new Image();
					image.data = jid;
					image.load(urlOrHash);
					image.addEventListener(Event.COMPLETE, imageCompleteHandler);
				}
				else
				{
					xmpp.getVCard(jid);
				}
			}
		}
		
		//--------------------------------
		// setBitmapString()
		//--------------------------------
		
		public function setBitmapString(jid:String, bitmapString:String):void
		{
			if(!bitmapString || bitmapString.length < 10)
				return;
			
			var base64Dec:Base64Decoder = new Base64Decoder();
			base64Dec.decode(bitmapString);
			var byteArray:ByteArray = base64Dec.toByteArray();
			
			var image:Image = new Image();
			image.addEventListener(Event.COMPLETE, imageCompleteHandler);
			image.data = jid;
			image.load(byteArray);
		}
		
		//--------------------------------
		// imageCompleteHandler()
		//--------------------------------
		
		private function imageCompleteHandler(event:Event):void
		{
			try
			{
				var image:Image = event.target as Image;
				image.removeEventListener(Event.COMPLETE, imageCompleteHandler);
				var bitmap:Bitmap = Bitmap(image.content);
				
				// if the bitmap is smaller than the AVATAR_SIZE, then scale it down
				// otherwise, just draw at the size we got it
				var scale:Number = AVATAR_SIZE / Math.max(bitmap.width, bitmap.height, AVATAR_SIZE);
				var matrix:Matrix = new Matrix(scale, 0, 0, scale);
				
				var bmd:BitmapData = new BitmapData(Math.min(bitmap.width*scale, AVATAR_SIZE), Math.min(bitmap.height*scale, AVATAR_SIZE));
				bmd.draw(bitmap, matrix);
				
				var jid:String = image.data as String;
				var avatar:Avatar = getAvatar(jid);
				avatar.bitmapData = bmd;

				if(avatar.tempUrlOrHash)
				{
					avatar.urlOrHash = avatar.tempUrlOrHash;
					avatar.tempUrlOrHash = null;
				}
			}
			catch(error:Error)
			{
				appModel.log(error);
			}
			catch(error:IOErrorEvent)
			{
				appModel.log(error);
			}
		}
		
		//--------------------------------
		// getAvatar()
		//--------------------------------
		
		private function saveHandler(event:Event):void
		{
			var avatar:Avatar = event.target as Avatar;
			databaseModel.saveAvatar(avatar);
		}

		//--------------------------------
		// getAvatar()
		//--------------------------------
		
		public function getAvatar(jid:String):Avatar
		{
			var avatar:Avatar = avatarCache[jid];
			if(!avatar)
			{
				avatar = databaseModel.loadAvatar(jid);
				if(!avatar)
				{
					avatar = new Avatar();
					avatar.jid = jid;
					avatar.addEventListener(AvatarEvent.SAVE, saveHandler);
				}
				avatarCache[jid] = avatar;
			}
			return avatar;
		}
	}
}