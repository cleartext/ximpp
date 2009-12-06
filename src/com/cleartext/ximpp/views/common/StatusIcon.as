package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.StatusEvent;
	import com.cleartext.ximpp.models.valueObjects.Status;
	
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;

	public class StatusIcon extends UIComponent
	{
		[Embed (source="../../assets/edit.png")]
		private var EditIcon:Class;
		
		[Embed (source="../../assets/delete.png")]
		private var CloseIcon:Class;
		
		public static const SIZE:Number = 14;
		
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
			status.addEventListener(StatusEvent.STATUS_CHANGED, statusChanged);
		}
		
//		private var textArea:UITextField;
		
		private var _status:Status = new Status();
		public function get status():Status
		{
			return _status;
		}
		private var colour:uint = DEFAULT;
		private var baseColour:uint = DEFAULT_B;
		
		public function statusChanged(event:StatusEvent):void
		{
			switch(status.value)
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
			
//			if(status.numUnread > 0)
//			{
//				textArea.text = status.numUnread.toString();
//				textArea.visible = true;
//			}
//			else
//			{
//				textArea.text = "";
//				textArea.visible = false;
//			}
			
			invalidateDisplayList();
		}
		
		public function set statusString(statusString:String):void
		{
			_status.value = statusString;
		}

		override protected function createChildren():void
		{
			super.createChildren();
			
//			if(!textArea)
//			{
//				textArea = new UITextField();
//				textArea.visible = false;
//				textArea.width = SIZE;
//				textArea.height = SIZE;
//				addChild(textArea);
//			}
			
		}
		
		private var showCloseIcon:Boolean = false;
		private var buttonModeChanged:Boolean = false;
		
		override public function get buttonMode():Boolean
		{
			return super.buttonMode;
		}
		override public function set buttonMode(value:Boolean):void
		{
			if(super.buttonMode != value)
			{
				super.buttonMode = value;
				buttonModeChanged = true;
				invalidateProperties();
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(buttonModeChanged)
			{
				if(buttonMode)
				{
					trace("adding listeners");
					addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
					addEventListener(MouseEvent.CLICK, clickHandler);
				}
				else
				{
					removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
					removeEventListener(MouseEvent.CLICK, clickHandler);
				}
				buttonModeChanged = false;
			}
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			trace("over 1");
			showCloseIcon = true;
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			trace("over 2");
			showCloseIcon = false;
			invalidateDisplayList();
		}
		
		private function clickHandler(event:MouseEvent):void
		{
			trace("click");
//			dispatchEvent(new StatusEvent(AvatarEvent.EDIT_CLICKED));
		}

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
			
			if(status.edit)
			{
				var editBitmapData:BitmapData = new EditIcon().bitmapData;
				var scale1:Number = SIZE / Math.max(editBitmapData.width, editBitmapData.height);
				g.beginBitmapFill(editBitmapData, new Matrix(scale1, 0, 0, scale1));
				g.drawRect(0,0,SIZE,SIZE);
			}
			
			if(showCloseIcon)
			{
				var closeBitmapData:BitmapData = new CloseIcon().bitmapData;
				var scale2:Number = (SIZE-2) / Math.max(closeBitmapData.width, closeBitmapData.height);
				g.beginBitmapFill(closeBitmapData, new Matrix(scale2, 0, 0, scale2, 1, 1));
				g.drawRect(1,1,SIZE-2,SIZE-2);
			}
		}

	}
}