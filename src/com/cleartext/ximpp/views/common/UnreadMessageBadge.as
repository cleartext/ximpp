package com.cleartext.ximpp.views.common
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	import mx.core.UITextField;

	public class UnreadMessageBadge extends UIComponent
	{
		public function UnreadMessageBadge()
		{
			super();
		}
		
		private var textField:UITextField;

		private var _count:int = 0;
		public function get count():int
		{
			return _count;
		}
		public function set count(value:int):void
		{
			if(count!=value)
			{
				_count = value;
				invalidateProperties();
				invalidateDisplayList();
			}
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!textField)
			{
				textField = new UITextField();
				textField.styleName = "whiteBold";
				textField.x = 3;
				addChild(textField);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(count > 0)
			{
				visible = true;
				if(count.toString() != textField.text)
					invalidateProperties();
				textField.text = count.toString();
				width = textField.textWidth + 11;
				height = textField.textHeight;
			}
			else
			{
				visible = false;
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(!visible)
				return;
			
			var g:Graphics = graphics;
			g.clear();

			var matr1:Matrix = new Matrix();
			matr1.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [0xff0000, 0xc0372d], [1, 1], [0x00, 0xFF], matr1);  
			g.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, unscaledHeight, unscaledHeight);
			
			g.beginGradientFill(GradientType.LINEAR, [0x636363, 0xe5e5e5], [1, 1], [0x00, 0xFF], matr1);
			g.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, unscaledHeight, unscaledHeight);
			g.drawRoundRect(1, 1, unscaledWidth-2, unscaledHeight-2, unscaledHeight-2, unscaledHeight-2);
		}
		
	}
}