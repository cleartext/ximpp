package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.models.valueObjects.Status;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;

	public class StatusIcon extends UIComponent
	{
		public static const SIZE:Number = 12;
		
		public static const GREEN:uint = 0x99cb26;
		private static const GREEN_B:uint = 0x438e29;

		public static const ORANGE:uint = 0xfad557;
		private static const ORANGE_B:uint = 0xea7b0e;

		public static const RED:uint = 0xc0372d;
		private static const RED_B:uint = 0x731c18;

		public static const TURQUOISE:uint = 0xaddbe5;
		private static const TURQUOISE_B:uint = 0x37b2c2;

		public static const VIOLET:uint = 0xc29dc3;
		private static const VIOLET_B:uint = 0x774b8f;

		public static const DEFAULT:uint = 0xcecece;
		private static const DEFAULT_B:uint = 0x7d7d7d;
		
		private static const SHADDOW:uint = 0x000000;
		
		public function StatusIcon()
		{
			super();
		}
		
		private var colour:uint = DEFAULT;
		private var baseColour:uint = DEFAULT_B;
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();

			var matr2:Matrix = new Matrix();
			matr2.createGradientBox(SIZE, SIZE/6, 0, 0, SIZE*11/12);
			g.beginGradientFill(GradientType.RADIAL, [SHADDOW, SHADDOW], [0.3, 0], [0x77, 0xFF], matr2);  
			g.drawEllipse(0, SIZE*11/12, SIZE, SIZE/6);

			var matr1:Matrix = new Matrix();
			matr1.createGradientBox(SIZE, SIZE, Math.PI/2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [colour, baseColour], [1, 1], [0x00, 0xFF], matr1);  
			g.drawCircle(SIZE/2, SIZE/2, SIZE/2);
		}
		
		private var _status:String = Status.UNKNOWN;
		public function get status():String
		{
			return _status;
		}
		public function set status(value:String):void
		{
			if(value == _status)
				return;
			
			_status = value;
			switch(_status)
			{
				case Status.AVAILABLE :
					colour = GREEN;
					baseColour = GREEN_B;
					break;
				case Status.AWAY :
					colour = ORANGE;
					baseColour = ORANGE_B;
					break;
				case Status.BUSY :
					colour = RED;
					baseColour = RED_B;
					break;
				case Status.CONNECTING :
					colour = TURQUOISE;
					baseColour = TURQUOISE_B;
					break;
				case Status.EXTENDED_AWAY :
					colour = ORANGE;
					baseColour = ORANGE_B;
					break;
				case Status.ERROR :
					colour = RED;
					baseColour = RED_B;
					break;
				default :
					colour = DEFAULT;
					baseColour = DEFAULT_B;
					break;
			}
			invalidateDisplayList();
		}
		
	}
}