package com.cleartext.esm.models.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Matrix;
	import flash.utils.ByteArray;
	
	import mx.controls.Image;
	import mx.graphics.codec.PNGEncoder;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	
	public class AvatarUtils
	{
		public static const AVATAR_SIZE:int = 48;
		
		public static function avatarToString(avatar:BitmapData):String
		{
			if(!avatar)
				return null;
			
			var byteArray:ByteArray = new PNGEncoder().encode(avatar);
			var base64Enc:Base64Encoder = new Base64Encoder();
			base64Enc.encodeBytes(byteArray);
			var result:String = base64Enc.flush();
			return result;
		}
		
		public static function stringToAvatar(avatarStr:String, host:Object, propertyName:String):void
		{
			if(!avatarStr || avatarStr.length < 10 || !host)
				return;
			
			var base64Dec:Base64Decoder = new Base64Decoder();
			base64Dec.decode(avatarStr);
			var byteArray:ByteArray = base64Dec.toByteArray();

			var image:Image = new Image();
			image.addEventListener(Event.COMPLETE, imageCompleteHandler);
			image.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			image.data = [host, propertyName];
			image.load(byteArray);
		}
				
		public static function ioErrorHandler(event:IOErrorEvent):void
		{
			// do nothing
			trace("ioErrorCaught");
		}
		
		public static function imageCompleteHandler(event:Event):void
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
				
				var host:Object = image.data[0];
				var propertyName:String = image.data[1];
				
				host[propertyName] = bmd;
			}
			catch(error:Error)
			{
				trace(error);
			}
			catch(error:IOErrorEvent)
			{
				trace(error);
			}
		}
	}
}