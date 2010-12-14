package com.cleartext.esm.views.common
{
	import com.cleartext.esm.assets.Constants;
	import com.cleartext.esm.events.AvatarEvent;
	import com.cleartext.esm.models.types.AvatarTypes;
	import com.cleartext.esm.models.valueObjects.Avatar;
	import com.cleartext.esm.models.valueObjects.Buddy;
	import com.cleartext.esm.models.valueObjects.BuddyGroup;
	import com.cleartext.esm.models.valueObjects.Chat;
	import com.cleartext.esm.models.valueObjects.ChatRoom;
	
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import mx.core.UIComponent;
	
	[Event(name="editClicked", type="com.cleartext.esm.events.AvatarEvent")]

	public class AvatarRenderer extends UIComponent
	{
		public function AvatarRenderer()
		{
			super();
		}
		
		protected var dirty:Boolean = true;
		
		private var _smallAvatar:Boolean = false;
		public function get smallAvatar():Boolean
		{
			return _smallAvatar;
		}
		public function set smallAvatar(value:Boolean):void
		{
			if(value != smallAvatar)
			{
				_smallAvatar = value;
				dirty=true;
				invalidateDisplayList();
			}
		}
		
		private var _showAvatar:Boolean = true;
		public function get showAvatar():Boolean
		{
			return _showAvatar;
		}
		public function set showAvatar(value:Boolean):void
		{
			if(value != showAvatar)
			{
				_showAvatar = value;
				dirty=true;
				invalidateDisplayList();
			}
		}
		
		private var _avatar:Avatar;
		public function get avatar():Avatar
		{
			return _avatar;
		}
		public function set avatar(value:Avatar):void
		{
			if(value != avatar)
			{
				if(avatar)
					avatar.removeEventListener(AvatarEvent.BITMAP_DATA_CHANGE, avatarChangedHandler);
				
				_avatar = value;
				if(avatar)
					avatar.addEventListener(AvatarEvent.BITMAP_DATA_CHANGE, avatarChangedHandler);

				dirty = true;
				invalidateDisplayList();
			}
		}
		
		protected function avatarChangedHandler(event:AvatarEvent):void
		{
			dirty = true;
			invalidateDisplayList();
		}
		
		private var _bitmapData:BitmapData;
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		public function set bitmapData(value:BitmapData):void
		{
			_bitmapData = value;
			dirty = true;
			invalidateDisplayList();
		}
		
		private var _type:String = AvatarTypes.BUDDY;
		public function get type():String
		{
			return _type;
		}
		public function set type(value:String):void
		{
			if(type != value)
			{
				_type = value;
				dirty = true;
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
		private var editModeChanged:Boolean = false;
		private var _editMode:Boolean = false;
		[Inspectable]
		public function get editMode():Boolean
		{
			return _editMode;
		}
		public function set editMode(value:Boolean):void
		{
			if(editMode != value)
			{
				_editMode = value;
				editModeChanged = true;
				invalidateProperties();
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(editModeChanged)
			{
				if(editMode)
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
				editModeChanged = false;
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
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			if(!dirty)
				return;
				
			var g:Graphics = graphics;
			g.clear();
			
			g.beginFill(0xffffff);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);

			if(!showAvatar)
				return;
			
			var bmd:BitmapData;
			if(bitmapData)
				bmd = bitmapData;
			else if(avatar)
				bmd = avatar.bitmapData;
			
			if(!bmd)
			{
				switch(type) 
				{
					case AvatarTypes.CHAT_ROOM :
						bmd = Constants.defaultMUCBmd;
						break;
					case AvatarTypes.ALL_MICRO_BLOGGING_BUDDY :
						bmd = Constants.defaultWorkstreamBmd;
						break;
					case AvatarTypes.GROUP :
						bmd = Constants.defaultGroupBmd;
						break;
					default :
						bmd = Constants.defaultAvatarBmd;
						break;
				}
			}

			var scale:Number = Math.min(unscaledWidth/bmd.width, unscaledHeight/bmd.height, 1);
			
			var w:Number = bmd.width * scale;
			var h:Number = bmd.height * scale;
			var tx:Number = (unscaledHeight - w)/2;
			var ty:Number = (unscaledHeight - h)/2;
			
			if(smallAvatar)
			{
				scale /= 2;
				w /= 2;
				h /= 2;
			}

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