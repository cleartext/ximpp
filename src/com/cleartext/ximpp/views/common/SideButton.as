package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.PopUpEvent;
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
	
	import org.swizframework.Swiz;

	public class SideButton extends UIComponent
	{
		
		[Autowire(bean="xmpp", property="connected")]
		[Bindable]
		public var connected:Boolean;
		
		private static const SELECTED_WIDTH:Number = 41;
		private static const NORMAL_WIDTH:Number = 32;
		private static const BAR_HEIGHT:Number = 32;

		private var textField:UITextField;
		private var image:Image;
		private var editButton:Button;
		private var deleteButton:Button;
		
		public var forceWhiteBackground:Boolean = false;
		
		private var hover:Boolean = false;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);

		private var _expandRight:Boolean = true;
		public function get exandRight():Boolean
		{
			return _expandRight;
		}
		public function set expandRight(value:Boolean):void
		{
			if(value != _expandRight)
			{
				_expandRight = value;
				invalidateProperties();
			}
		}

		private var _showEditButton:Boolean = true;
		public function get showEditButton():Boolean
		{
			return _showEditButton;
		}
		public function set showEditButton(value:Boolean):void
		{
			if(value != _showEditButton)
			{
				_showEditButton = value;
				invalidateProperties();
			}
		}

		private var _icon:Class;
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

			buttonMode = true;
			
			filters = [dropShaddow];
			
			width = NORMAL_WIDTH;
			height = NORMAL_WIDTH;
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			hover = true;
			textField.visible = true;
			editButton.visible = deleteButton.visible = showEditButton;
			width = textField.textWidth + 65;
			invalidateDisplayList();
			
			editButton.enabled = deleteButton.enabled = connected;

			editButton.toolTip = (connected) ? "edit group" : "go online to edit";
			deleteButton.toolTip = (connected) ? "remove group" : "go online to remove";

			if(selected)
				filters = [dropShaddow];
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			hover = false;
			textField.visible = false;
			editButton.visible = false;
			deleteButton.visible = false;
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
				textField.y = 9;
				textField.mouseEnabled = false;
				addChild(textField);
			}
			
			if(!image)
			{
				image = new Image();
				image.source = icon;
				image.width = 32;
				image.height = 32;
				image.mouseEnabled = false;
				addChild(image);
			}
			
			if(!editButton)
			{
				editButton = new Button();
				editButton.visible = false;
				editButton.setStyle("skin", null);
				editButton.setStyle("upIcon", Constants.EditUp);
				editButton.setStyle("overIcon", Constants.EditOver);
				editButton.setStyle("downIcon", Constants.EditUp);
				editButton.setStyle("disabledIcon", Constants.EditUp);
				editButton.width = 16;
				editButton.height = 16;
				editButton.addEventListener(MouseEvent.CLICK, edit_clickHandler);
				addChild(editButton);
			}
			
			if(!deleteButton)
			{
				deleteButton = new Button();
				deleteButton.visible = false;
				deleteButton.setStyle("skin", null);
				deleteButton.setStyle("upIcon", Constants.CloseUp);
				deleteButton.setStyle("overIcon", Constants.CloseOver);
				deleteButton.setStyle("downIcon", Constants.CloseUp);
				deleteButton.setStyle("disabledIcon", Constants.CloseUp);
				deleteButton.width = 16;
				deleteButton.height = 16;
				deleteButton.addEventListener(MouseEvent.CLICK, delete_clickHandler);
				addChild(deleteButton);
			}
		}
		
		private function delete_clickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.DELETE_GROUP_WINDOW, text));
		}
		
		private function edit_clickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			Swiz.dispatchEvent(new PopUpEvent(PopUpEvent.EDIT_GROUP_WINDOW, text));
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			textField.styleName = "dGreyBold";
			textField.setActualSize(textField.textWidth+10, textField.textHeight+10);
			
			textField.x = (exandRight) ? 42 : (-10 -textField.width);
			
			editButton.move(textField.textWidth + 56, 8);
			deleteButton.move(textField.textWidth + 78, 8);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();
			
			var xVal:Number = exandRight ? 0 : (-textField.width -10);
			var wVal:Number = unscaledWidth + ((deleteButton.visible) ? 35 : 0);
			
			if(selected)
			{
				g.beginFill(0xffffff)
				if(hover)
					g.drawRoundRect(xVal,0,wVal,BAR_HEIGHT, 10, 10);
				else
					g.drawRoundRectComplex(xVal, 0, wVal, BAR_HEIGHT, 5, 0, 5, 0);
			}
			else
			{
				var m:Matrix = new Matrix();
				m.createGradientBox(wVal, BAR_HEIGHT, Math.PI/2, xVal);
				
				g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xe1e1e1, 0xd1d1d1], [1,1,1], [0x00, 0x79, 0x80], m);
				g.drawRoundRect(xVal,0,wVal,BAR_HEIGHT, 10, 10);
			}
			
			if(deleteButton.visible)
			{
				g.beginFill(0x000000, 0.35);
				g.drawRect(wVal - 25, 5, 1, unscaledHeight-10);
				g.drawRect(wVal - 48, 5, 1, unscaledHeight-10);
			}
		}
	}
}