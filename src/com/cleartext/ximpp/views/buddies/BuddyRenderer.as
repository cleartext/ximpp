package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.events.AvatarEvent;
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	import mx.core.UITextField;
	import mx.effects.Tween;

	public class BuddyRenderer extends SproutListItemBase
	{
		private static const SMALL_HEIGHT:Number = 40;
		private static const BIG_HEIGHT:Number = 46;
		private static const AVATAR_SIZE:Number = 32;

		private static const PADDING:Number = 3;
		
		//---------------------------------------
		// Constructor
		//---------------------------------------
		
		public function BuddyRenderer(initialWidth:Number=NaN, initialHeight:Number=NaN)
		{
			super(initialWidth, SMALL_HEIGHT);
			heightTo = SMALL_HEIGHT;
		}

		private function get buddy():Buddy
		{
			return data as Buddy;
		}
		
		override public function set data(value:Object):void
		{
			if(buddy)
				buddy.removeEventListener(BuddyEvent.CHANGED, buddyChangedHandler);
			
			super.data = value;

			if(buddy)
			{
				buddy.addEventListener(BuddyEvent.CHANGED, buddyChangedHandler);
				if(avatar)
					avatar.data = buddy;
			}
			else
			{
				avatar.data = null;
			}

			invalidateProperties();
		}
		
		private function isAvailable():Boolean
		{
			return (buddy && buddy.status.isAvailable());
		}
		
		private function buddyChangedHandler(event:BuddyEvent):void
		{
			invalidateProperties();
			invalidateDisplayList();
		}
		
		//---------------------------------------
		// Size Tween
		//---------------------------------------
		
		private var sizeTween:Tween;
		
		//---------------------------------------
		// Display Children
		//---------------------------------------
		
		private var avatar:Avatar;
		private var statusIcon:StatusIcon;
		private var nameLabel:UITextField;
		private var statusLabel:UITextField;
		private var customStatusLabel:UITextField
		
		//---------------------------------------
		// Create Children
		//---------------------------------------
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatar)
			{
				avatar = new Avatar();
				avatar.buttonMode = true;
				avatar.x = PADDING;
				avatar.y = PADDING;
				avatar.width = AVATAR_SIZE;
				avatar.height = AVATAR_SIZE;
				avatar.addEventListener(AvatarEvent.EDIT_CLICKED, avatarClicked);
				avatar.data = buddy;
				addChild(avatar);
			}
			
			if(!statusIcon)
			{
				statusIcon = new StatusIcon();
				statusIcon.width = StatusIcon.SIZE;
				statusIcon.height = StatusIcon.SIZE;
				statusIcon.y = 12;
				addChild(statusIcon);
			}

			if(!nameLabel)
			{
				nameLabel = new UITextField();
				nameLabel.x = AVATAR_SIZE + 2*PADDING;
				nameLabel.y = PADDING;
				addChild(nameLabel);
			}

			if(!statusLabel)
			{
				statusLabel = new UITextField();
				statusLabel.styleName = "lGreyNormal";
				statusLabel.x = AVATAR_SIZE + 2*PADDING;
				statusLabel.y = 16;
				addChild(statusLabel);
			}
			
			if(!customStatusLabel)
			{
				customStatusLabel = new UITextField();
				customStatusLabel.styleName = "lGreyNormal";
				customStatusLabel.x = AVATAR_SIZE + 2*PADDING
				customStatusLabel.y = 31;
				customStatusLabel.visible = false;
				addChild(customStatusLabel);
			}
		}
		
		//---------------------------------------
		// Commit Properties
		//---------------------------------------
		
		override protected function commitProperties():void
		{
			if(!buddy)
				return;
	
			// set values
			customStatusLabel.text = buddy.customStatus;
			nameLabel.text = buddy.nickName;
			statusLabel.text = buddy.status.value;
			statusIcon.status.value = buddy.status.value;
			
			// What height we should be depends if there is a custom
			// status to show. If there is no custom status, then make
			// sure the label is not visible and we should be at the 
			// SMALL_HEIGHT
			var h:Number;
			if(!buddy.customStatus || buddy.customStatus == "")
			{
				customStatusLabel.visible = false;
				h = SMALL_HEIGHT;
			}
			else
			{
				h = BIG_HEIGHT;
			}
			
			// If we are at, or currently tweening to the height we
			// should be, then stop any active tweens and create a
			// new one (creating a tween automatically plays it)
			if(h != heightTo)
			{
				_heightTo = h;
				if(sizeTween)
					sizeTween.stop();
				
				sizeTween = new Tween(this, height, h, TWEEN_DURATION, -1, updateHeight,
					// on complete...
					function():void
					{
						customStatusLabel.visible = true;
						// when we aren't playing, tweens should be null
						sizeTween = null;
						// confirm we are at the right height (removes rounding errors
						// from the tween)
						updateHeight(heightTo);
						// check everything is ok
						commitProperties();
					});
			}
			
			if(buddy.status.isAvailable())
			{
				nameLabel.styleName = "dGreyBold";
				avatar.alpha = 1;
				alpha = 1;
			} 
			else
			{
				nameLabel.styleName = "lGreyBold";
				avatar.alpha = 0.5;
				alpha = 0.6;
			}

			statusIcon.x = width - PADDING - StatusIcon.SIZE;
			
			var maxWidth:Number = width - AVATAR_SIZE - 3*PADDING;
			nameLabel.width = maxWidth;

			customStatusLabel.width = maxWidth;
			customStatusLabel.truncateToFit();

		}

		override public function setWidth(widthVal:Number):Number
		{
			width = widthVal;
			return heightTo;
		}

		private function avatarClicked(event:AvatarEvent):void
		{
			dispatchEvent(new BuddyEvent(BuddyEvent.EDIT_BUDDY, true));
		}
		
		//---------------------------------------
		// Update Display List
		//---------------------------------------
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var g:Graphics = graphics;
			g.clear();

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			
			g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			
			if(buddy && buddy.status.isAvailable())
			{
				g.beginFill(0x000000, 0.15)
				g.drawRect(0, unscaledHeight-1, unscaledWidth, 1);
			}
		}
	}		
}