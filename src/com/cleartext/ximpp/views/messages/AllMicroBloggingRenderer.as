package com.cleartext.ximpp.views.messages
{
	import com.cleartext.ximpp.views.common.Avatar;
	
	public class AllMicroBloggingRenderer extends MicroBloggingRenderer
	{
		protected var serviceAvatar:Avatar;
		
		public function AllMicroBloggingRenderer()
		{
			super();
		}

		override protected function get bodyTextWidth():Number
		{
			return width - 6.5*padding - 1.5*avatarSize - buttonWidth;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!serviceAvatar)
			{
				serviceAvatar = new Avatar();
				serviceAvatar.width = avatarSize*2/3;
				serviceAvatar.height = avatarSize*2/3;
				serviceAvatar.border = false;
				serviceAvatar.alpha = 0.5;
				serviceAvatar.y = padding;
				serviceAvatar.x = avatarSize + 3*padding + buttonWidth;	
				addChildAt(serviceAvatar, 0);
			}
			
			bodyTextField.x = 1.5*avatarSize + 5*padding + buttonWidth;
			nameTextField.x = 1.5*avatarSize + 5*padding + buttonWidth;
			dateTextField.x = 1.5*avatarSize + 5*padding + buttonWidth;
		}

		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(message)
			{
				serviceAvatar.data = appModel.getBuddyByJid((fromThisUser) ? message.recipient : message.sender);
			}
		}
		
	}
}