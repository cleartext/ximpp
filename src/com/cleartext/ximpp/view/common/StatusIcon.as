package com.cleartext.ximpp.view.common
{
	import com.cleartext.ximpp.models.valueObjects.Status;
	
	import mx.controls.Image;

	public class StatusIcon extends Image
	{
		public static const GREEN:String = "green";
		public static const ORANGE:String = "orange";
		public static const RED:String = "red";
		public static const TURQUOISE:String = "turquoise";
		public static const VIOLET:String = "violet";
		public static const DEFAULT:String = "grey";
		
		[Embed(source="../../assets/green_button.png")]
        private var greenIcon:Class;
		
		[Embed(source="../../assets/orange_button.png")]
        private var orangeIcon:Class;
		
		[Embed(source="../../assets/red_button.png")]
        private var redIcon:Class;
		
		[Embed(source="../../assets/turquoise_button.png")]
        private var turquoiseIcon:Class;
		
		[Embed(source="../../assets/violet_button.png")]
        private var violetIcon:Class;
		
		[Embed(source="../../assets/grey_button.png")]
        private var greyIcon:Class;
		
		public function StatusIcon()
		{
			super();
			
			width = 16;
			height = 16;
		}
		
		override public function set source(value:Object):void
		{
			// do nothing
		}
		
		private var _colour:String = null;
		public function get colour():String
		{
			return _colour;
		}
		public function set colour(value:String):void
		{
			if(value == _colour)
				return;
			
			_colour = value;
			switch(_colour)
			{
				case GREEN :
					super.source = greenIcon;
					break;
				case ORANGE :
					super.source = orangeIcon;
					break;
				case RED :
					super.source = redIcon;
					break;
				case TURQUOISE :
					super.source = turquoiseIcon;
					break;
				case VIOLET :
					super.source = violetIcon;
					break;
				default :
					super.source = greyIcon;
					break;
			}
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
					break;
				case Status.AWAY :
					colour = ORANGE;
					break;
				case Status.BUSY :
					colour = RED;
					break;
				case Status.CONNECTING :
					colour = TURQUOISE;
					break;
				case Status.EXTENDED_AWAY :
					colour = ORANGE;
					break;
				case Status.ERROR :
					colour = RED;
					break;
				default :
					colour = DEFAULT;
					break;
			}
		}
		
	}
}