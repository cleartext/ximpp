package com.cleartext.esm.views.common
{
	import flash.display.Sprite;
	
	import mx.controls.Image;

	public class RoundedImage extends Image
	{
		protected var roundedMask:Sprite;
		
		public function RoundedImage()
		{
			super();
		}
		
		private var _radius:Number = 0;
		public function get radius():Number
		{
			return _radius;
		}
		public function set radius(value:Number):void
		{
			_radius = value;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!roundedMask)
			{
				roundedMask = new Sprite();
				addChild(roundedMask);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			roundedMask.graphics.clear();
			roundedMask.graphics.beginFill(0x000000);
			roundedMask.graphics.drawRoundRectComplex(0, 0, unscaledWidth, unscaledHeight, radius, radius, radius, radius);
			roundedMask.graphics.endFill();
			
			mask = roundedMask;
		}
	}
}