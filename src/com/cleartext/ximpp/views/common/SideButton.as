package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.models.Constants;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.core.UITextField;

	public class SideButton extends UIComponent
	{
		private static const SELECTED_WIDTH:Number = 41;
		private static const NORMAL_WIDTH:Number = 32;
//		private static const TRIANGLE_WIDTH:Number = 8;

		private var textField:UITextField;
		private var image:Image;
		private var deleteButton:Button;
		
		private var hover:Boolean = false;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);
		public var expandRight:Boolean = true;

		private var _icon:Class = Constants.DefaultGroupIcon;
		public function get icon():Class
		{
			return _icon;
		}
		public function set icon(value:Class):void
		{
			_icon = value;
			if(image)
				image.source = icon;
		}
		
		private var _selected:Boolean = false;
		public function get selected():Boolean
		{
			return _selected;
		}
		public function set selected(value:Boolean):void
		{
			if(_selected != value)
			{
				_selected = value;
				
				if(hover)
				{
					width = textField.textWidth + 65;
					filters = [dropShaddow];
				}
				else if(selected)
				{
					width = SELECTED_WIDTH;
					filters = [];
				}
				else
				{
					width = NORMAL_WIDTH;
					filters = [dropShaddow];
				}
				invalidateDisplayList();
			}
		}
		
		private var _text:String;
		public function get text():String
		{
			return _text;
		}
		public function set text(value:String):void
		{
			if(_text != value)
			{
				_text = value;
				if(textField)
					textField.text = _text;
			}
		}
		
		public function SideButton()
		{
			super();
			
			filters = [dropShaddow];
			
			width = NORMAL_WIDTH;
			height = NORMAL_WIDTH;
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			deleteButton.visible = true;
			hover = true;
			textField.visible = true;
			width = textField.textWidth + 65;
			invalidateDisplayList();
			
			if(selected)
				filters = [dropShaddow];
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			deleteButton.visible = false;
			hover = false;
			textField.visible = false;
			width = selected ? SELECTED_WIDTH : NORMAL_WIDTH;
			invalidateDisplayList();

			if(selected)
				filters = [];
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!textField)
			{
				textField = new UITextField();
				textField.text = text;
				textField.visible = hover;
				textField.x = 34;
				textField.y = 9;
				textField.mouseEnabled = false;
				addChild(textField);
			}
			
			if(!image)
			{
				image = new Image();
				image.source = icon;
				image.x = 2;
				image.y = 5;
				image.width = 29;
				image.height = 25;
				image.mouseEnabled = false;
				addChild(image);
			}
			
			if(!deleteButton)
			{
				deleteButton = new Button();
				deleteButton.setStyle("skin", null);
				deleteButton.setStyle("upIcon", Constants.CloseUp);
				deleteButton.setStyle("overIcon", Constants.CloseOver);
				deleteButton.setStyle("downIcon", Constants.CloseUp);
				deleteButton.addEventListener(MouseEvent.CLICK, delete_ClickHandler);
				deleteButton.buttonMode = true;
				deleteButton.visible = false;
				deleteButton.setActualSize(14, 14);
				addChild(deleteButton);
			}
		}
		
		private function delete_ClickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			textField.styleName = "dGreyBold";
			textField.setActualSize(textField.textWidth+10, textField.textHeight+10);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			deleteButton.move(unscaledWidth - 18, 9);
			
			var g:Graphics = graphics;
			g.clear();
			
			if(selected)
			{
				g.beginFill(0xffffff)
				if(hover)
					g.drawRoundRect(0,0,unscaledWidth,unscaledHeight,8,8);
				else
					g.drawRoundRectComplex(0, 0, unscaledWidth, unscaledHeight, 4, 0, 4, 0);

//				g.moveTo(unscaledWidth-TRIANGLE_WIDTH, 0);
//				g.lineTo(unscaledWidth, unscaledHeight/2);
//				g.lineTo(unscaledWidth-TRIANGLE_WIDTH, unscaledHeight);
//				g.lineTo(unscaledWidth-TRIANGLE_WIDTH, 0);
			}
			else
			{
				var m:Matrix = new Matrix();
				m.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
				
				g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xe1e1e1, 0xd1d1d1], [1,1,1], [0x00, 0x79, 0x80], m);
				g.drawRoundRect(0,0,unscaledWidth,unscaledHeight,8,8);
			}
			
			if(hover)
			{
//				g.beginFill(0x
			}
		}
		
	}
}