package com.cleartext.ximpp.models
{
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
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
		
		public static function stringToAvatar(avatarStr:String, buddy:Buddy):void
		{
			if(!avatarStr || !buddy)
				return;
			
			var base64Dec:Base64Decoder = new Base64Decoder();
			base64Dec.decode(avatarStr);
			var byteArray:ByteArray = base64Dec.toByteArray();

			var image:Image = new Image();
			image.load(byteArray);
			image.data = buddy;
			image.addEventListener(Event.COMPLETE, imageCompleteHandler);
		}
		
		public static function imageCompleteHandler(event:Event):void
		{
			var image:Image = event.target as Image;
			var bitmap:Bitmap = Bitmap(image.content);
			
			// if the bitmap is smaller than the AVATAR_SIZE, then scale it down
			// otherwise, just draw at the size we got it
			var scale:Number = AVATAR_SIZE / Math.max(bitmap.width, bitmap.height, AVATAR_SIZE);
			var matrix:Matrix = new Matrix(scale, 0, 0, scale);

			var bmd:BitmapData = new BitmapData(Math.min(bitmap.width*scale, AVATAR_SIZE), Math.min(bitmap.height*scale, AVATAR_SIZE));
			bmd.draw(bitmap, matrix);
			
			(image.data as Buddy).avatar = bmd;
			image.removeEventListener(Event.COMPLETE, imageCompleteHandler);
		}
	}
}