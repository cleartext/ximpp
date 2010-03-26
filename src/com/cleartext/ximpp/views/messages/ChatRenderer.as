package com.cleartext.ximpp.views.messages
{
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	public class ChatRenderer extends MessageRendererBase
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
		
		public function ChatRenderer()
		{
			super();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			avatar.visible = showTopRow;
			dateTextField.visible = showTopRow;
			nameTextField.visible = showTopRow;
			
			avatar.includeInLayout = showTopRow;
			dateTextField.includeInLayout = showTopRow;
			nameTextField.includeInLayout = showTopRow;
			
			bodyTextField.y = showTopRow ? topRowHeight+padding : padding;
			dateTextField.x = width - dateTextField.width - 2*padding;	
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
			
			avatar.x = 2*padding;
			avatar.y = 2;

			nameTextField.y = padding + 2;
			nameTextField.x = avatarSize + 5*padding;

			dateTextField.y = padding + 2;
			dateTextField.x = width - dateTextField.width - 2*padding;	

			bodyTextField.x = avatarSize + 5*padding;
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
	
				if(fromThisUser)
					g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
				else
					g.beginGradientFill(GradientType.LINEAR, [0xeeeeee, 0xbbbbbb], [0.5, 0.5], [95, 255], matrix);

				g.drawRoundRect(4*padding + avatarSize, 2, width-5*padding-avatarSize, topRowHeight-4, 10, 10);
			}
			else
			{
				g.lineStyle(1, 0xdedede);
				
				var xVal:Number = 6*padding + avatarSize;
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