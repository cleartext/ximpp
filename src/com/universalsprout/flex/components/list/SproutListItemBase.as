package com.universalsprout.flex.components.list
{
	import flash.events.Event;
	
	import mx.controls.Text;
	import mx.effects.Tween;
	import mx.events.PropertyChangeEvent;
	import mx.events.ResizeEvent;
	
	public class SproutListItemBase extends Text implements ISproutListItem
	{
		protected static const TWEEN_DURATION:Number = 500;
		protected static const TOP_BAR_HEIGHT:Number = 16;
		protected static const UITEXTFIELD_WIDTH_PADDING:Number = 5;
		protected static const UITEXTFIELD_HEIGHT_PADDING:Number = 4;

		public function SproutListItemBase()
		{
		}
		
		protected var textFieldHeight:Number;

		protected var moveTween:Tween;

		protected var _wordWrap:Boolean = true;
		public function get wordWrap():Boolean
		{
			return _wordWrap;
		}
		public function set wordWrap(value:Boolean):void
		{
			if(_wordWrap != value)
			{
				_wordWrap = value;
				invalidateProperties();
			}
		}
		
		override public function get data():Object
		{
			return super.data;
		}
		override public function set data(value:Object):void
		{
			if(data)
				(data as ISproutListData).removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, dataChangedHandler);
			
			super.data = value;
			
			if(data)
			{
				(data as ISproutListData).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, dataChangedHandler);
				invalidateProperties();
			}
		}
		
		protected var _used:Boolean = false;
		public function get used():Boolean
		{
			return _used;
		}
		public function set used(value:Boolean):void
		{
			_used = value;
		}
		
		protected var _highlight:Boolean = false;
		public function get highlight():Boolean
		{
			return _highlight;
		}
		public function set highlight(value:Boolean):void
		{
			_highlight = value;
			invalidateDisplayList();
		}
		
		protected var _heightTo:Number = NaN;
		public function get heightTo():Number
		{
			return (isNaN(_heightTo)) ? height : _heightTo;
		}
		
		protected var _yTo:Number = NaN;
		public function get yTo():Number
		{
			return (isNaN(_yTo)) ? y : _yTo;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			textField.wordWrap = wordWrap;
			
			var paddingLeft:Number = getStyle("paddingLeft");
			var paddingRight:Number = getStyle("paddingRight");

			textField.width = width - paddingLeft - paddingRight;
			
			textFieldHeight = UITEXTFIELD_HEIGHT_PADDING;
			for(var l:int=textField.numLines-1; l>=0; l--)
			{
				textFieldHeight += Math.ceil(textField.getLineMetrics(l).height);
			}
		}
		
		protected function dataChangedHandler(event:Event):void
		{
			// override this
		}
		
		public function tweenTo(xMove:Number, yMove:Number):void
		{
			super.move(xMove, y);
			
			if(yMove == yTo)
				return;

			if(moveTween)
				moveTween.stop();

			_yTo = yMove;

			moveTween = new Tween(this, y, yMove, TWEEN_DURATION, -1, updateY,
				function():void
				{
					moveTween = null;
					updateY(yTo);
					_yTo = NaN;
					commitProperties();
				});
		}
		
		protected function updateAlpha(value:Number):void
		{
			alpha = value;
		}
		
		protected function updateY(value:Number):void
		{
			super.move(x, value);
			dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE));
		}
		
		protected function updateHeight(value:Number):void
		{
			setActualSize(width, value);
		}
		
		protected function onTweenEnd(value:Number):void
		{
			// do nothing
		}
	}
}