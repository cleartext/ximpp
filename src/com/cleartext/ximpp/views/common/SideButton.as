package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.PopUpEvent;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.LinkButton;
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
//		private static const TRIANGLE_WIDTH:Number = 8;

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

			editButton.toolTip = (connected) ? "" : "go online to edit";
			deleteButton.toolTip = (connected) ? "" : "go online to delete";

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
				editButton = new LinkButton();
				editButton.setActualSize(70, 18);
				editButton.move(11+NORMAL_WIDTH, BAR_HEIGHT+2);
				editButton.setStyle("themeColor", 0x444444);
				editButton.visible = false;
				editButton.label = "edit";
				editButton.addEventListener(MouseEvent.CLICK, edit_clickHandler);
				addChild(editButton);
			}
			
			if(!deleteButton)
			{
				deleteButton = new LinkButton();
				deleteButton.setActualSize(70, 18);
				deleteButton.move(11+NORMAL_WIDTH, BAR_HEIGHT+22);
				deleteButton.setStyle("themeColor", 0x444444);
				deleteButton.visible = false;
				deleteButton.label = "delete";
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
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();
			
			var xVal:Number = exandRight ? 0 : (-textField.width -10);
			
			if(selected)
			{
				g.beginFill(0xffffff)
				if(hover)
					g.drawRoundRect(xVal,0,unscaledWidth,BAR_HEIGHT, 10, 10);
				else
					g.drawRoundRectComplex(xVal, 0, unscaledWidth, BAR_HEIGHT, 5, 0, 5, 0);

//				g.moveTo(unscaledWidth-TRIANGLE_WIDTH, 0);
//				g.lineTo(unscaledWidth, unscaledHeight/2);
//				g.lineTo(unscaledWidth-TRIANGLE_WIDTH, BAR_HEIGHT);
//				g.lineTo(unscaledWidth-TRIANGLE_WIDTH, 0);
			}
			else
			{
				var m:Matrix = new Matrix();
				m.createGradientBox(unscaledWidth, BAR_HEIGHT, Math.PI/2, xVal);
				
				g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xe1e1e1, 0xd1d1d1], [1,1,1], [0x00, 0x79, 0x80], m);
				g.drawRoundRect(xVal,0,unscaledWidth,BAR_HEIGHT, 10, 10);
			}
			
			if(hover && showEditButton)
			{
				g.beginFill(0xffffff);
				g.drawRect(9+NORMAL_WIDTH, BAR_HEIGHT, 74, 42);
			}
		}
		
	}
}