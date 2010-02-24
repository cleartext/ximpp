package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.SearchBoxEvent;
	import com.cleartext.ximpp.models.Constants;
	
	import flash.display.Graphics;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;

	/**
	 * @inheritDoc
	 */
	[Event(name="search", type="com.cleartext.ximpp.events.SearchBoxEvent")]

	public class SearchBox extends Canvas
	{
		private var textInput:DefaultTextInput;
		private var resetButton:Button;
		private var searchString:String;
		
		public var borderAlpha:Number = 1;
	
		public function SearchBox()
		{
			super();
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!textInput)
			{
				textInput = new DefaultTextInput();
				textInput.defaultText = "Search...";
				textInput.multiLine = false;
				textInput.addEventListener(KeyboardEvent.KEY_UP, textInputHandler);
				textInput.setStyle("cornerRadius", 12);
				textInput.setStyle("paddingTop", 5);
				textInput.setStyle("paddingLeft", 24);
				textInput.setStyle("paddingRight", 24);
				textInput.setStyle("backgroundAlpha", 0);
				textInput.setStyle("borderStyle", "none");
				textInput.wordWrap = false;
				textInput.horizontalScrollPolicy = "off";
				textInput.verticalScrollPolicy = "off";
				addChild(textInput);
			}
			
			if(!resetButton)
			{
				resetButton = new Button();
				resetButton.addEventListener(MouseEvent.CLICK, resetButtonHandler);
				resetButton.visible = false;
				resetButton.setStyle("skin", null);
				resetButton.setStyle("upIcon", Constants.CloseUp);
				resetButton.setStyle("overIcon", Constants.CloseOver);
				resetButton.setStyle("downIcon", Constants.CloseUp);
				resetButton.buttonMode = true;
				addChild(resetButton);
			}
		}
		
		private function textInputHandler(event:KeyboardEvent):void
		{
			textInput.multiLine = false;
			setSearchString();
		}
		
		private function resetButtonHandler(event:MouseEvent):void
		{
			textInput.reset(true);
			setSearchString();
		}
		
		private function setSearchString():void
		{
			resetButton.visible = (textInput.text.length > 0);
			
			if(textInput.text != searchString)
			{
				searchString = textInput.text;
				dispatchEvent(new SearchBoxEvent(searchString));
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			textInput.setActualSize(unscaledWidth, unscaledHeight);
			
			var buttonDims:Number = textInput.height - 6;
			
			resetButton.setActualSize(buttonDims, buttonDims);
			resetButton. move(unscaledWidth - 3 - buttonDims, 3);
			
			// draw background
			var g:Graphics = graphics;
			
			g.clear();
			
			g.beginFill(0xffffff);
			g.drawRoundRect(1, 0, unscaledWidth-2, 23, 23, 23);
			g.endFill();
			
			g.lineStyle(2.5, 0x5b5b5b);
			g.drawCircle(12, 11, 5); 

			g.lineStyle(3, 0x5b5b5b);
			g.moveTo(16, 15);
			g.lineTo(20, 19);
			
			g.lineStyle(2, 0xeaeaea, borderAlpha);
//			g.lineStyle(2, 0x4a4b4d, 0.12);
			g.drawRoundRect(2, 3, unscaledWidth-4, 19, 19, 19);
			
			g.lineStyle(1, 0xeaeaea, 0.4 * borderAlpha);
//			g.lineStyle(1, 0x4a4b4d, 0.32);
			g.drawRoundRect(1, 2, unscaledWidth-2, 22, 22, 22);
			
//			g.lineStyle(1, 0x808080);
			g.lineStyle(1, 0x4a4b4d, 0.62 * borderAlpha);
			g.drawRoundRect(1, 1, unscaledWidth-2, 23, 23, 23);
			
			g.lineStyle(1, 0x4a4b4d, borderAlpha);
			g.drawRoundRect(1, 0, unscaledWidth-2, 23, 23, 23);
		}
		
	}
}