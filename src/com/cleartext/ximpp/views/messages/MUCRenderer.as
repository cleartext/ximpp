package com.cleartext.ximpp.views.messages
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	import flash.text.TextFieldAutoSize;
	
	public class MUCRenderer extends MessageRendererBase
	{
		private var showTopRowChanged:Boolean = false;
		private var _showTopRow:Boolean = true;
		public function get showTopRow():Boolean
		{
			return _showTopRow;
		}
		public function set showTopRow(value:Boolean):void
		{
			if(_showTopRow != value)
			{
				showTopRowChanged = true;
				_showTopRow = value;
				invalidateProperties();
			}
		}
		
		public function MUCRenderer()
		{
			super();
		}
		
		override protected function get bodyTextWidth():Number
		{
			return width - 6*padding;
		}
		
		override protected function commitProperties():void
		{
			if(message)
			{
				dateTextField.visible =
					nameTextField.visible = showTopRow;
				
				dateTextField.includeInLayout =
					nameTextField.includeInLayout = showTopRow;

				if(showTopRow)
				{
					nameTextField.text = message.groupChatSender;
					nameTextField.width = nameTextField.textWidth + padding*4;
					nameTextField.styleName = "blackBold";
	
					dateTextField.text = df.format(message.sentTimestamp);
					dateTextField.width = dateTextField.textWidth + padding*2;
					dateTextField.styleName = "blackSmall";
					dateTextField.x = width - dateTextField.width - 2*padding;	

					bodyTextField.y = topRowHeight+padding;
				}
				else
				{
					bodyTextField.y = padding;
				}

				if(message.displayMessage)
					bodyTextField.htmlText = message.displayMessage;
				else
					bodyTextField.text = message.plainMessage;

				bodyTextField.styleName = "blackNormal";
				
			}
			
			heightInvalid = true;
			calculateHeight();
		}
		
		override protected function calculateHeight():Number
		{
			heightTo = super.calculateHeight() + padding + ((showTopRow) ? topRowHeight : 0);
			return heightTo;
		}
		
		override public function set yTo(value:Number):void
		{
			if(showTopRowChanged)
			{
				move(0, value);
				showTopRowChanged = false;
			}
			else
				super.yTo = value;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			removeChild(avatar);
			avatar = null;

			nameTextField.y = padding + 2;
			nameTextField.x = 3*padding;

			dateTextField.y = padding + 2;
			dateTextField.x = width - dateTextField.width - 2*padding;
			dateTextField.autoSize = TextFieldAutoSize.RIGHT;

			bodyTextField.x = 3*padding;
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();

			if(showTopRow)
			{
				var matrix:Matrix = new Matrix();
				matrix.createGradientBox(width, topRowHeight, Math.PI/2);
				g.beginGradientFill(GradientType.LINEAR, [0xeeeeee, 0xbbbbbb], [0.5, 0.5], [95, 255], matrix);
				g.drawRoundRect(2*padding, 2, width-3*padding, topRowHeight-4, 10, 10);
			}
			else
			{
				g.lineStyle(1, 0xdedede);
				
				var xVal:Number = 4*padding;
				var dash:Number = 3;
				var gap:Number = 3;	
				var limit:Number = xVal + 60;
				
				while(xVal < limit)
				{
					g.moveTo(xVal, 0);
					xVal += dash;
					g.lineTo(xVal, 0);
					xVal += gap;
				}
			}
		}
	}
}