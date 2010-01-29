package com.cleartext.ximpp.views.common
{
	import com.cleartext.ximpp.events.AvatarEvent;
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	
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
		
		private var _data:Object;
		public function get data():Object
		{
			return _data;
		}
		public function set data(value:Object):void
		{
			if(_data != value)
			{
				if(buddy)
					buddy.removeEventListener(BuddyEvent.CHANGED, buddyChangedHandler);
				
				_data = value;
				
				if(buddy)
					buddy.addEventListener(BuddyEvent.CHANGED, buddyChangedHandler, false, 0, true);
			}
			buddyChangedHandler(null);
		}
		
		private function get buddy():Buddy
		{
			if(data is Buddy)
				return data as Buddy;
			
			if(data is Chat)
				return (data as Chat).buddy;
			
			return null;
		}
		
		public function get chat():Chat
		{
			return data as Chat;
		}
		
		private function buddyChangedHandler(event:BuddyEvent):void
		{
			var bmd:BitmapData = (buddy) ? buddy.avatar : null;
			
			if(bmd != bitmapData)
			{
				if(bmd)
				{
					bitmapData = new BitmapData(bmd.width, bmd.height, bmd.transparent);
					bitmapData.draw(bmd);
				}
				else
					bitmapData = null;

				invalidateDisplayList();
			}
		}
		
		private var bitmapData:BitmapData;
		public function getBitmapData():BitmapData
		{
			return bitmapData;
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