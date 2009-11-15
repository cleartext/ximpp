package com.cleartext.ximpp.views.common
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;

	public class Avatar extends UIComponent
	{
		[Embed(source="com/cleartext/ximpp/assets/user.jpg")]
		private var DefaultAvatar:Class;
		
		public function Avatar()
		{
			super();
		}
		
		private var _bitmapData:BitmapData;
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		public function set bitmapData(value:BitmapData):void
		{
			if(_bitmapData != value)
			{
				if(value)
				{
					_bitmapData = new BitmapData(value.width, value.height, value.transparent);
					_bitmapData.draw(value);
				}
				else
					_bitmapData = null;

				invalidateDisplayList();
			}
		}
		
		private var _border:Boolean = true;
		public function get border():Boolean
		{
			return _border;
		}
		public function set border(value:Boolean):void
		{
			if(_border != border)
			{
				_border = value;
				invalidateDisplayList();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			
			var bmd:BitmapData = (bitmapData) ? bitmapData : new DefaultAvatar().bitmapData;
			
			var scale:Number = Math.min(unscaledWidth/bmd.width, unscaledHeight/bmd.height); 
			g.beginBitmapFill(bmd, new Matrix(scale, 0, 0, scale));
	
			if(border)
				g.lineStyle(1, 0x888888);
	
			g.drawRect(0,0,width,height);
		}

		
	}
}