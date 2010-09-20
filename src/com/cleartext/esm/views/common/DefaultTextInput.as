package com.cleartext.esm.views.common
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.text.TextFieldAutoSize;
	
	import mx.controls.TextArea;
	import mx.core.IUITextField;
	import mx.core.UITextField;
	
	public class DefaultTextInput extends TextArea
	{
		//----------------------------------
		// focusFlag
		//----------------------------------
		
		public var hasFocus:Boolean = false;
		
		//----------------------------------
		// defaultTextField
		//----------------------------------
		
		private var defaultTextField:IUITextField;
		
		//----------------------------------
		// defaultText
		//----------------------------------
		
		private var _defaultText:String = "";
		public function get defaultText():String
		{
			return _defaultText;
		}
		public function set defaultText(value:String):void
		{
			if(defaultText != value)
			{
				_defaultText = value;
				if(defaultTextField)
					defaultTextField.text = defaultText;
			}
		}
		
		override public function set text(value:String):void
		{
			super.text = value;
			showOrHideDefaultTextField();
		}
		
		//----------------------------------
		// CONSTRUCTOR
		//----------------------------------
		
		public function DefaultTextInput()
		{
			super();
			showOrHideDefaultTextField();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		public function set multiline(value:Boolean):void
		{
			if(textField)
				textField.multiline = value;
		}
		
		override protected function focusInHandler(event:FocusEvent):void
		{
			super.focusInHandler(event);
			hasFocus = true;
			showOrHideDefaultTextField();
		}
		
		override protected function focusOutHandler(event:FocusEvent):void
		{
			super.focusOutHandler(event);
			hasFocus = false;
			showOrHideDefaultTextField();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(defaultTextField && textField)
			{
				defaultTextField.move(textField.x, textField.y);
				defaultTextField.setActualSize(textField.width, textField.height);
			}
		}
		
		protected function addedToStageHandler(event:Event):void
		{
			showOrHideDefaultTextField();
		}

		protected function showOrHideDefaultTextField():void
		{
			var show:Boolean = !hasFocus && !text && defaultText;
			
			if(defaultTextField)
			{
				if(defaultTextField.visible != show)
				{
					defaultTextField.visible = show;
					invalidateDisplayList();
				}
			}
			else if(show)
			{
				defaultTextField = IUITextField(createInFontContext(UITextField));
			
				defaultTextField.autoSize = TextFieldAutoSize.NONE;
				defaultTextField.styleName = this;
				defaultTextField.text = defaultText;
				defaultTextField.enabled = false;
				defaultTextField.includeInLayout = false;
				
				addChild(DisplayObject(defaultTextField));
			}
		}
	}
}