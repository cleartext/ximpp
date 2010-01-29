package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.events.AvatarEvent;
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.universalsprout.flex.components.list.SproutListItemBase;
	
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.effects.Tween;

	public class BuddyRenderer extends SproutListItemBase
	{
		//---------------------------------------
		// Constants
		//---------------------------------------
		
		private static const SMALL_HEIGHT:Number = 40;
		private static const BIG_HEIGHT:Number = 56;

		private static const PADDING:Number = 3;
		
		private static const NO_HIGHLIGHT:uint = 0xffffff;
		private static const HIGHLIGHT:uint = 0xdddddd;

		//---------------------------------------
		// Constructor
		//---------------------------------------
		
		public function BuddyRenderer()
		{
			super();
			height = SMALL_HEIGHT;
			wordWrap = false;
			truncateToFit = true;
		}
		
		//---------------------------------------
		// Buddy Data
		//---------------------------------------
		
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
		
		private function buddyChangedHandler(event:BuddyEvent):void
		{
			invalidateProperties();
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
		private function get customStatusLabel():IUITextField
		{
			return textField;
		}
		
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
				avatar.addEventListener(AvatarEvent.EDIT_CLICKED, avatarClicked);
				avatar.data = buddy;
				addChild(avatar);
			}
			
			if(!statusIcon)
			{
				statusIcon = new StatusIcon();
				addChild(statusIcon);
			}

			if(!nameLabel)
			{
				nameLabel = new UITextField();
				addChild(nameLabel);
			}

			if(!statusLabel)
			{
				statusLabel = new UITextField();
				addChild(statusLabel);
			}
			
			customStatusLabel.visible = false;
			customStatusLabel.wordWrap = wordWrap;
		}
		
		//---------------------------------------
		// Commit Properties
		//---------------------------------------
		
		override protected function commitProperties():void
		{
			if(!buddy)
				return;
			
			customStatusLabel.wordWrap = false;

			// set values
			customStatusLabel.text = buddy.customStatus;
			nameLabel.text = buddy.nickName;
			statusLabel.text = buddy.status.value;
			statusIcon.status.value = buddy.status.value;
			
			// refresh styles
			nameLabel.styleName = "dgreyNormal";
			statusLabel.styleName = "lgreyNormal";
			customStatusLabel.styleName = "dgreyNormal";
			
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
						_heightTo = NaN;
						// check everything is ok
						commitProperties();
					});
			}
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
			commitProperties();
			
			var avatarSize:Number = 32;
			
			// draw background
			graphics.clear();
			graphics.beginFill((highlight) ? HIGHLIGHT : NO_HIGHLIGHT, 0.18);
			graphics.drawRect(0, 0, unscaledWidth-1, unscaledHeight);
			
			// layout avatar
			avatar.setActualSize(avatarSize, avatarSize);
			avatar.move(PADDING, PADDING)
			
			// layout name label
			nameLabel.setActualSize(unscaledWidth - avatarSize - 3*PADDING, nameLabel.height);
			nameLabel.move(avatarSize + 2*PADDING, PADDING);

			// layout status icon
			statusIcon.setActualSize(StatusIcon.SIZE, StatusIcon.SIZE);
			statusIcon.move(unscaledWidth - PADDING - StatusIcon.SIZE, 15);

			// layout status label
			statusLabel.setActualSize(unscaledWidth - avatarSize - 4*PADDING - StatusIcon.SIZE, statusLabel.height); 
			statusLabel.move(avatarSize + 2*PADDING, 20);

			// layout custom status label
			customStatusLabel.setActualSize(unscaledWidth-2*PADDING, customStatusLabel.height);
			customStatusLabel.move(avatarSize + 2*PADDING, 39);
			customStatusLabel.truncateToFit();
		}
	}
}