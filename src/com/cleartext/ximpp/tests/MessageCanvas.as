package com.cleartext.ximpp.tests
{
	import com.cleartext.ximpp.models.AvatarUtils;
	import com.cleartext.ximpp.models.valueObjects.Chat;
	import com.cleartext.ximpp.views.common.Avatar;
	
	import flash.display.Graphics;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.ScrollPolicy;
	import mx.effects.Fade;
	import mx.effects.Move;
	
	public class MessageCanvas extends Canvas
	{
		private static const ANIMATION_DURATION:Number = 350;

		private static const H_GAP:Number = 8;
		private static const SELECTOR_WIDTH:Number = 5;
		private static const TRIANGLE_HEIGHT:Number = 11;
		private static const TRIANGLE_WIDTH:Number = 16;
		private static const INPUT_HEIGHT:Number = 105;
		
		private static const SELECTED_ALPHA:Number = 1.0;
		private static const OVER_ALPHA:Number = 0.8;
		private static const OUT_ALPHA:Number = 0.3;
		
		private var avatars:ArrayCollection = new ArrayCollection();

		private var avatarCanvas:Canvas;
		private var selectorCanvas:Canvas;
		private var messageCanvas:Canvas;
		private var inputCanvas:Canvas;

		private var _index:int = 0;
		public function get index():int
		{
			return _index;
		}
		public function set index(value:int):void
		{
			_index = value;
			refreshIndex();
		}
		
		private function refreshIndex():void
		{
			if(_index >= avatars.length)
				_index = 0;
			else if(_index < 0)
				_index = Math.max(avatars.length -1, 0);
			
			var currentAvatar:Avatar = avatarByIndex(index);
			if(currentAvatar)
				setCurrentChat(currentAvatar.chat);
		}
		
		public function MessageCanvas()
		{
			super();
		}
		
		public function numChats():int
		{
			return avatars.length;
		}
		
		private function avatarByIndex(i:int):Avatar
		{
			if(avatars.length > 0)
				return avatars.getItemAt(i) as Avatar;
			return null;
		}
		
		public function setCurrentChat(chat:Chat):void
		{
			if(!chat)
				return;

			// select the current one move and fade it or
			// create a new avatar
			var exists:Boolean = false;
			for(var i:int=0; i<avatars.length; i++)
			{
				if(avatarByIndex(i).chat == chat)
				{
					_index = i;
					moveAvatar(index, 1, SELECTED_ALPHA);
					exists = true;
					break;
				}
			}
			
			if(!exists)
			{
				var avatar:Avatar = new Avatar();
				avatar.data = chat;
				avatar.addEventListener(MouseEvent.CLICK, avatarClickHandler, false, 0, true);
				avatar.width = AvatarUtils.AVATAR_SIZE;
				avatar.height = AvatarUtils.AVATAR_SIZE;
				avatar.border = false;
				avatar.toolTip = chat.buddy.nickname;
				avatar.addEventListener(MouseEvent.ROLL_OVER, avatar_rollOver);
				avatar.addEventListener(MouseEvent.ROLL_OUT, avatar_rollOut); 
				avatar.alpha = 0;

				avatars.addItemAt(avatar, index);
				moveAvatar(index, 1, SELECTED_ALPHA, false);
				avatarCanvas.addChildAt(avatar, 0);
			}
			
			// do all the other avatars
			var cursor:int = index+1;
			for(var j:int=1; j<avatars.length; j++)
			{
				if(cursor >= avatars.length)
					cursor = 0;
				
				// the last avatar needs to go to position 0
				moveAvatar(cursor, (j==avatars.length-1) ? 0 : j+1, OUT_ALPHA);
				cursor++;
			}
		}
		
		private function avatar_rollOver(event:MouseEvent):void
		{
			var avatar:Avatar = event.target as Avatar;
			if(avatarByIndex(index) != avatar)
				avatar.alpha = OVER_ALPHA;
		}
		
		private function avatar_rollOut(event:MouseEvent):void
		{
			var avatar:Avatar = event.target as Avatar;
			if(avatarByIndex(index) != avatar)
				avatar.alpha = OUT_ALPHA;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatarCanvas)
			{
				avatarCanvas = new Canvas();
				avatarCanvas.horizontalScrollPolicy = ScrollPolicy.OFF;
				addChild(avatarCanvas);
			}
			
			if(!selectorCanvas)
			{
				selectorCanvas = new Canvas();
				avatarCanvas.addChild(selectorCanvas);
			}
			
			if(!inputCanvas)
			{
				inputCanvas = new Canvas();
				addChild(inputCanvas);
			}
			
			if(!messageCanvas)
			{
				messageCanvas = new Canvas();
				messageCanvas.setStyle("backgroundColor", 0xffffff);
				addChild(messageCanvas);
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			inputCanvas.setActualSize(unscaledWidth, INPUT_HEIGHT);
			inputCanvas.move(0, 0);
			
			avatarCanvas.setActualSize(unscaledWidth, AvatarUtils.AVATAR_SIZE + SELECTOR_WIDTH + TRIANGLE_HEIGHT);
			avatarCanvas.move(0, INPUT_HEIGHT);
			
			messageCanvas.setActualSize(unscaledWidth, unscaledHeight - INPUT_HEIGHT - avatarCanvas.height);
			messageCanvas.move(0, INPUT_HEIGHT + avatarCanvas.height);
			
			selectorCanvas.move(AvatarUtils.AVATAR_SIZE + 2*H_GAP, 0);
			selectorCanvas.setActualSize(AvatarUtils.AVATAR_SIZE + 2*SELECTOR_WIDTH, avatarCanvas.height);

			var g:Graphics = selectorCanvas.graphics;
			g.clear();
			g.beginFill(0xffffff);
			g.moveTo((selectorCanvas.width-TRIANGLE_WIDTH)/2, 0);
			g.lineTo((selectorCanvas.width+TRIANGLE_WIDTH)/2, 0);
			g.lineTo(selectorCanvas.width/2, TRIANGLE_HEIGHT-2);
			g.lineTo((selectorCanvas.width-TRIANGLE_WIDTH)/2, 0);
			g.drawRect(0, TRIANGLE_HEIGHT, AvatarUtils.AVATAR_SIZE + 2*SELECTOR_WIDTH, AvatarUtils.AVATAR_SIZE + SELECTOR_WIDTH);
			g.drawRect(SELECTOR_WIDTH, TRIANGLE_HEIGHT + SELECTOR_WIDTH, AvatarUtils.AVATAR_SIZE, AvatarUtils.AVATAR_SIZE);
		}
		
		private function avatarClickHandler(event:MouseEvent):void
		{
			setCurrentChat((event.target as Avatar).chat);
		}
		
		private function moveAvatar(avatarIndex:int, position:int, newAlpha:Number=-1, animate:Boolean=true):void
		{
			var avatar:Avatar = avatarByIndex(avatarIndex);
			
			if(newAlpha != -1 && newAlpha != avatar.alpha)
			{
				var fade:Fade = new Fade(avatar);
				fade.alphaFrom = avatar.alpha;
				fade.alphaTo = newAlpha;
				fade.duration = ANIMATION_DURATION;
				fade.play();
			}

			var newX:Number = (AvatarUtils.AVATAR_SIZE + H_GAP)*position + H_GAP;

			if(position == 1)
				newX += SELECTOR_WIDTH;
			else if(position >1)
				newX += 2*SELECTOR_WIDTH;

			var newY:Number = SELECTOR_WIDTH + TRIANGLE_HEIGHT;

			if(animate && (avatar.x != newX || avatar.y != newY))
			{
				var move:Move = new Move(avatar);
				move.duration = ANIMATION_DURATION;
				move.xTo = newX;
				move.yTo = newY;
				move.play();
			}
			else
			{
				avatar.move(newX, newY);
			}
		}
		
		public function removeChat(chat:Chat=null):void
		{
			if(avatars.length == 0)
				return;
			
			if(chat)
			{
				for each(var a:Avatar in avatars)
				{
					if(a.chat == chat)
					{
						avatarCanvas.removeChild(a);
						avatars.removeItemAt(avatars.getItemIndex(a));
						break;
					}
				}
			}
			else
			{
				avatarCanvas.removeChild(avatarByIndex(index));
				avatars.removeItemAt(index);
			}
			
			// make sure index is valid and layout the avatars
			refreshIndex();
		}
	}
}