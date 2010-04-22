package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.assets.Constants;
	import com.cleartext.ximpp.events.AvatarEvent;
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.models.valueObjects.IBuddy;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	
	[Event(name="editClicked", type="com.cleartext.ximpp.events.AvatarEvent")]

	public class Avatar extends UIComponent
	{
		public function Avatar()
		{
			super();
		}
		
		protected var dirty:Boolean = true;
		
		private var _data:Object;
		public function get data():Object
		{
			return _data;
		}
		public function set data(value:Object):void
		{
			if(_data != value)
			{
				dispose();
				
				_data = value;
				
				if(buddy)
					buddy.addEventListener(BuddyEvent.CHANGED, buddyChangedHandler, false, 0, true);

				buddyChangedHandler(null);
			}
		}
		
		public function get buddy():IBuddy
		{
			if(data is IBuddy)
				return data as IBuddy;
			
			if(data is Chat)
				return (data as Chat).buddy;
			
			return null;
		}
		
		protected function buddyChangedHandler(event:BuddyEvent):void
		{
			var bmd:BitmapData = (buddy) ? buddy.avatar : null;
			if(bmd != bitmapData)
			{
				_bitmapData = bmd;
				dirty = true;
				invalidateDisplayList();
			}
		}
		
		private var _bitmapData:BitmapData;
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
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
				dirty = true;
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
				{
					dirty = true;
					invalidateDisplayList();
				}
			}
		}
		
		private var _borderThickness:int = 1;
		public function get borderThickness():uint
		{
			return _borderThickness;
		}
		public function set borderThickness(value:uint):void
		{
			if(_borderThickness != value)
			{
				_borderThickness = value;
				if(border)
				{
					dirty = true;
					invalidateDisplayList();
				}
			}
		}
		
		private var showEditIcon:Boolean = false;
		private var buttonModeChanged:Boolean = false;
		[Inspectable]
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
					addEventListener(MouseEvent.ROLL_OVER, rollOverHandler, false, 0, true);
					addEventListener(MouseEvent.ROLL_OUT, rollOutHandler, false, 0, true);
					addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
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
			dirty = true;
			invalidateDisplayList();
		}
		
		private function rollOutHandler(event:MouseEvent):void
		{
			showEditIcon = false;
			dirty = true;
			invalidateDisplayList();
		}
		
		private function clickHandler(event:MouseEvent):void
		{
			dispatchEvent(new AvatarEvent(AvatarEvent.EDIT_CLICKED));
		}
		
		public function dispose(input:*=null):void
		{
			if(buddy)
				buddy.removeEventListener(BuddyEvent.CHANGED, buddyChangedHandler);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(!dirty)
				return;
				
			var g:Graphics = graphics;
			g.clear();
			var bmd:BitmapData = (bitmapData) ? bitmapData : Constants.defaultAvatarBmd;

			var scale:Number = Math.min(unscaledWidth/bmd.width, unscaledHeight/bmd.height, 1); 
			var w:Number = bmd.width * scale;
			var h:Number = bmd.height * scale;
			var tx:Number = (unscaledWidth - w)/2;
			var ty:Number = (unscaledHeight - h)/2;
			
			g.beginFill(0xffffff);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			g.drawRect(tx,ty,w,h);
			
			g.beginBitmapFill(bmd, new Matrix(scale, 0, 0, scale, tx, ty), false, true);

			g.drawRect(tx,ty,w,h);
			g.endFill();

			if(border)
			{
				g.lineStyle(borderThickness, borderColour);
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			}
	
			if(showEditIcon)
			{
				var transform:ColorTransform = new ColorTransform();
				transform.alphaMultiplier = 0.85;
				var editBitmapData:BitmapData = Constants.editIconBmd;
				editBitmapData.colorTransform(editBitmapData.rect, transform);
				
				scale = Math.min(unscaledWidth/editBitmapData.width, unscaledHeight/editBitmapData.height);
				g.beginBitmapFill(editBitmapData, new Matrix(scale, 0, 0, scale));
				g.drawRect(0,0,unscaledWidth,unscaledHeight);
			}
			
			dirty = false;
		}
	}
}