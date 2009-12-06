package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.AvatarEvent;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;

	[Event(name="editClicked", type="com.cleartext.ximpp.events.AvatarEvent")]

	public class Avatar extends UIComponent
	{
		[Embed (source="../../assets/edit.png")]
		private var EditIcon:Class;

		[Embed(source="../../assets/user.jpg")]
		private var DefaultAvatar:Class;
		
		public function Avatar()
		{
			super();
		}
		
		private var _bitmapData:BitmapData;
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		public function set bitmapData(value:BitmapData):void
		{
			if(_bitmapData != value)
			{
				if(value)
				{
					_bitmapData = new BitmapData(value.width, value.height, value.transparent);
					_bitmapData.draw(value);
				}
				else
					_bitmapData = null;

				invalidateDisplayList();
			}
		}
		
		private var _border:Boolean = true;
		public function get border():Boolean
		{
			return _border;
		}
		public function set border(value:Boolean):void
		{
			if(_border != value)
			{
				_border = value;
				invalidateDisplayList();
			}
		}
		
		private var _borderColour:uint = 0xaaaaaa;
		public function get borderColour():uint
		{
			return _borderColour;
		}
		public function set borderColour(value:uint):void
		{
			if(_borderColour != value)
			{
				_borderColour = value;
				if(border)
					invalidateDisplayList();
			}
		}
		
		private var showEditIcon:Boolean = false;
		private var buttonModeChanged:Boolean = false;
		
		override public function get buttonMode():Boolean
		{
			return super.buttonMode;
		}
		override public function set buttonMode(value:Boolean):void
		{
			if(super.buttonMode != value)
			{
				super.buttonMode = value;
				buttonModeChanged = true;
				invalidateProperties();
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(buttonModeChanged)
			{
				if(buttonMode)
				{
					addEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
					addEventListener(MouseEvent.CLICK, clickHandler);
				}
				else
				{
					removeEventListener(MouseEvent.ROLL_OVER, rollOverHandler);
					removeEventListener(MouseEvent.ROLL_OUT, rollOutHandler);
					removeEventListener(MouseEvent.CLICK, clickHandler);
				}
				buttonModeChanged = false;
			}
		}
		
		private function rollOverHandler(event:MouseEvent):void
		{
			showEditIcon = true;
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			showEditIcon = false;
			invalidateDisplayList();
		}
		
		private function clickHandler(event:MouseEvent):void
		{
			dispatchEvent(new AvatarEvent(AvatarEvent.EDIT_CLICKED));
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var g:Graphics = graphics;
			g.clear();
			
			var bmd:BitmapData = (bitmapData) ? bitmapData : new DefaultAvatar().bitmapData;
			
			var scale:Number = Math.min(unscaledWidth/bmd.width, unscaledHeight/bmd.height); 
			g.beginBitmapFill(bmd, new Matrix(scale, 0, 0, scale));
	
			if(border)
				g.lineStyle(1, borderColour);
	
			g.drawRect(0,0,unscaledWidth,unscaledHeight);

			if(showEditIcon)
			{
				var editBitmapData:BitmapData = new EditIcon().bitmapData;
				var transform:ColorTransform = new ColorTransform();
				transform.alphaMultiplier = 0.85;
				editBitmapData.colorTransform(editBitmapData.rect, transform);
				
				scale = Math.min(unscaledWidth/editBitmapData.width, unscaledHeight/editBitmapData.height);
				g.beginBitmapFill(editBitmapData, new Matrix(scale, 0, 0, scale));
				g.drawRect(0,0,unscaledWidth,unscaledHeight);
			}
		}

		
	}
}