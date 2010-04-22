package com.universalsprout.flex.components.list
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	import mx.core.IInvalidating;
	import mx.effects.Tween;
	import mx.events.PropertyChangeEvent;
	import mx.events.ResizeEvent;
	
	public class SproutListRendererBase extends NonInvalidatingUIComponent implements ISproutListRenderer
	{
		protected static const TWEEN_DURATION:Number = 500;
		protected static const UITEXTFIELD_WIDTH_PADDING:Number = 5;
		protected static const UITEXTFIELD_HEIGHT_PADDING:Number = 4;
		
		public function SproutListRendererBase(initialWidth:Number=NaN, initialHeight:Number=NaN)
		{
			super(initialWidth, initialHeight);
			addEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler, false, 0, true);
		}

		protected var moveTween:Tween;
		
		private var _data:Object;
		public function get data():Object
		{
			return _data;
		}
		public function set data(value:Object):void
		{
			if(data is IEventDispatcher)
				(data as IEventDispatcher).removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, dataChangedHandler);
			
			_data = value;
			
			if(data is IEventDispatcher)
			{
				(data as IEventDispatcher).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, dataChangedHandler, false, 0, true);
				invalidateProperties();
			}
		}
				
		protected var _heightTo:Number = NaN;
		public function get heightTo():Number
		{
			return (isNaN(_heightTo)) ? height : _heightTo;
		}
		public function set heightTo(value:Number):void
		{
			if(_heightTo != value)
			{
				var oldHeight:Number = _heightTo;
				_heightTo = value;
				dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE, false, false, width, oldHeight));
			}
		}
		
		protected var _yTo:Number = NaN;
		public function get yTo():Number
		{
			return (isNaN(_yTo)) ? y : _yTo;
		}
		public function set yTo(value:Number):void
		{
			if(value == yTo)
				return;

			if(moveTween)
				moveTween.stop();

			_yTo = value;

			moveTween = new Tween(this, y, yTo, TWEEN_DURATION, -1, updateY,
				function():void
				{
					moveTween = null;
					updateY(yTo);
					_yTo = NaN;
					invalidateProperties();
				});
		}
		
		public function setWidth(widthVal:Number):Number
		{
			return 0;
		}
		
		protected function dataChangedHandler(event:Event):void
		{
			// override this
		}
		
		protected function updateAlpha(value:Number):void
		{
			alpha = value;
		}
		
		protected function updateY(value:Number):void
		{
			var p:IInvalidating = parent as IInvalidating;
			if(p)
				p.invalidateDisplayList();
			y = value;
		}
		
		protected function updateHeight(value:Number):void
		{
			height = value;
		}
		
		protected function onTweenEnd(value:Number):void
		{
			// do nothing
		}

		protected function removeFromStageHandler(event:Event):void
		{
			dispose();
		}
		
		public function dispose():void
		{
//			removeEventListener(Event.REMOVED_FROM_STAGE, removeFromStageHandler);
//			(data as ISproutListData).removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, dataChangedHandler);
		}
	}
}