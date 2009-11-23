package com.cleartext.ximpp.views.common
{
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	
	import mx.controls.TextInput;

	public class DefaultTextInput extends TextInput
	{
		private var textSet:Boolean = false;
		private var _defaultText:String;
		
		public function get defaultText():String
		{
			return _defaultText;
		}
		public function set defaultText(value:String):void
		{
			if(_defaultText != value)
			{
				_defaultText = value;
				reset();
			}
		}
		
		override public function get text():String
		{
			return (textSet) ? super.text : "";
		}
		override public function set text(value:String):void
		{
			if(value == "")
				reset(true);
			else
			{
				setStyle("color", 0x000000);
				textSet = true;
				super.text = value;
			}
		}
		
		public function DefaultTextInput()
		{
			super();
		}
		
		override protected function keyDownHandler(event:KeyboardEvent):void
		{
			super.keyDownHandler(event);
			textSet = true;
		}
		
		public function reset(forceReset:Boolean=false, toDefault:Boolean=true):void
		{
			if(super.text == "" || forceReset)
			{
				textSet = false;
				if(toDefault)
				{
					super.text = _defaultText;
					setStyle("color", 0x555555);
				}
				else
				{
					super.text = "";
				}
			}
		}
		
		override protected function focusInHandler(event:FocusEvent):void
		{
			super.focusInHandler(event);
			if(super.text == defaultText)
			{
				super.text = "";
				setStyle("color", 0x000000);
			}
		}
		
		override protected function focusOutHandler(event:FocusEvent):void
		{
			super.focusOutHandler(event);
			reset();
		}
		
	}
}