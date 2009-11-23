package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.SearchBoxEvent;
	import com.cleartext.ximpp.models.ApplicationModel;
	
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
		
		[Autowire]
		[Bindable]
		public var appModel:ApplicationModel;		
		
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
				textInput.addEventListener(KeyboardEvent.KEY_UP, textInputHandler);
				addChild(textInput);
			}
			
			if(!resetButton)
			{
				resetButton = new Button();
				resetButton.addEventListener(MouseEvent.CLICK, resetButtonHandler);
				addChild(resetButton);
			}
		}
		
		private function textInputHandler(event:KeyboardEvent):void
		{
			setSearchString();
		}
		
		private function resetButtonHandler(event:MouseEvent):void
		{
			textInput.reset(true);
			setSearchString();
		}
		
		private function setSearchString():void
		{
			if(textInput.text != searchString)
			{
				searchString = textInput.text;
				dispatchEvent(new SearchBoxEvent(searchString));
				appModel.log("Search: " + searchString);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var top:Number = viewMetricsAndPadding.top;
			var right:Number = viewMetricsAndPadding.right;
			var bottom:Number = viewMetricsAndPadding.bottom;
			var left:Number = viewMetricsAndPadding.left;
			
			textInput.setActualSize(unscaledWidth - left - right, unscaledHeight - top - bottom);
			textInput.move(left, top);
			
			var buttonDims:Number = textInput.height - 6;
			
			resetButton.setActualSize(buttonDims, buttonDims);
			resetButton. move(unscaledWidth - right - 3 - buttonDims, top + 3);
		}
		
	}
}