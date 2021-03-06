package com.cleartext.esm.views.common
{
	import com.cleartext.esm.assets.Constants;
	import com.cleartext.esm.events.PopUpEvent;
	import com.cleartext.esm.models.XMPPModel;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	
	import mx.controls.Button;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	
	import org.swizframework.Swiz;

	public class SideButton extends UIComponent
	{
		[Autowire]
		[Bindable]
		public var xmpp:XMPPModel;
		
		private static const SELECTED_WIDTH:Number = 41;
		private static const NORMAL_WIDTH:Number = 32;
		private static const BAR_HEIGHT:Number = 32;

		private var textField:UITextField;
		private var image:RoundedImage;
		private var editButton:Button;
		private var deleteButton:Button;
		private var broadcastButton:Button;
		
		public var forceWhiteBackground:Boolean = false;
		
		private var hover:Boolean = false;
		private var dropShaddow:DropShadowFilter = new DropShadowFilter(2);

		private var _data:Object;
		public function get data():Object
		{
			return _data;
		}
		public function set data(value:Object):void
		{
			if(_data != value)
			{
				_data = value;
			}
		}

		private var _expandRight:Boolean = true;
		public function get expandRight():Boolean
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
					filters = [dropShaddow];
				else if(selected)
					filters = [];
				else
					filters = [dropShaddow];

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

			width = NORMAL_WIDTH;
			height = NORMAL_WIDTH;
			
			filters = [dropShaddow];
			
			addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
			addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			hover = true;
			textField.visible = true;

			editButton.visible = 
				deleteButton.visible = 
				broadcastButton.visible = 
				showEditButton;

			invalidateDisplayList();
			
			editButton.enabled = deleteButton.enabled = xmpp.connected;

			if(!showEditButton)
			{
				editButton.toolTip = null;
				deleteButton.toolTip = null;
				broadcastButton.toolTip = null;
			}
			else if(xmpp.connected)
			{
				editButton.toolTip = "edit group";
				deleteButton.toolTip = "remove group";
				broadcastButton.toolTip = "broadcast to group";
			}
			else
			{
				editButton.toolTip = "go online to edit";
				deleteButton.toolTip = "go online to remove";
				broadcastButton.toolTip = "broadcast to group";
			}

			if(selected)
				filters = [dropShaddow];
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			hover = false;
			textField.visible = false;
			editButton.visible = false;
			deleteButton.visible = false;
			broadcastButton.visible = false;
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
				textField.mouseEnabled = false;
				addChild(textField);
			}
			
			if(!image)
			{
				image = new RoundedImage();
				image.radius = 10;
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
			
			if(!broadcastButton)
			{
				broadcastButton = new Button();
				broadcastButton.visible = false;
				broadcastButton.setStyle("skin", null);
				broadcastButton.setStyle("upIcon", Constants.BroadcastUp);
				broadcastButton.setStyle("overIcon", Constants.BroadcastOver);
				broadcastButton.setStyle("downIcon", Constants.BroadcastUp);
				broadcastButton.setStyle("disabledIcon", Constants.BroadcastUp);
				broadcastButton.width = 16;
				broadcastButton.height = 16;
				broadcastButton.addEventListener(MouseEvent.CLICK, broadcast_clickHandler);
				addChild(broadcastButton);
			}
		}
		
		private function broadcast_clickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.NEW_CHAT_WITH_GROUP);
			popupEvent.group = text;
			Swiz.dispatchEvent(popupEvent);
		}
		
		private function delete_clickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.DELETE_GROUP_WINDOW);
			popupEvent.group = text;
			Swiz.dispatchEvent(popupEvent);
		}
		
		private function edit_clickHandler(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.EDIT_GROUP_WINDOW);
			popupEvent.group = text;
			Swiz.dispatchEvent(popupEvent);
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			textField.styleName = "dGreyBold";
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			textField.setActualSize(textField.textWidth+10, textField.textHeight+10);

			var xVal:Number = 0;
			
			if(textField.visible)
			{
				xVal = (expandRight) ? 42 : (-textField.width-5);
				textField.move(xVal, 9);
			}

			if(broadcastButton.visible)
			{
				xVal = (expandRight) ? textField.textWidth + 55 : - textField.textWidth - 42;
				broadcastButton.move(xVal, 8);
			}
			
			if(editButton.visible)
			{
				xVal = (expandRight) ? textField.textWidth + 80 : - textField.textWidth - 67;
				editButton.move(xVal, 8);
			}
	
			if(deleteButton.visible)
			{
				xVal = (expandRight) ? textField.textWidth + 102 : - textField.textWidth - 89;
				deleteButton.move(xVal, 8);
			}
			
			var wVal:Number = 0;
			
			if(hover)
			{
				wVal = textField.textWidth + 55;
				if(showEditButton)
					wVal += 68;
			}
			else
			{
				wVal = (selected) ? SELECTED_WIDTH : NORMAL_WIDTH;
			}

			xVal = (expandRight) ? 0 : - wVal + NORMAL_WIDTH;
			
			var g:Graphics = graphics;
			g.clear();
			
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
				g.drawRect((expandRight) ? (wVal - 25) : (-wVal + 54), 5, 1, unscaledHeight-10);
				g.drawRect((expandRight) ? (wVal - 48) : (-wVal + 77), 5, 1, unscaledHeight-10);
			}
		}
	}
}