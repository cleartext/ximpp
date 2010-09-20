package com.cleartext.esm.views.messages
{
	import com.cleartext.esm.models.types.AvatarTypes;
	import com.cleartext.esm.views.common.AvatarRenderer;
	
	public class AllMicroBloggingRenderer extends MicroBloggingRenderer
	{
		protected var serviceAvatar:AvatarRenderer;
		
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
				serviceAvatar = new AvatarRenderer();
				serviceAvatar.width = avatarSize*2/3;
				serviceAvatar.height = avatarSize*2/3;
				serviceAvatar.border = false;
				serviceAvatar.alpha = 0.5;
				serviceAvatar.y = padding;
				serviceAvatar.x = avatarSize + 3*padding + buttonWidth;	
				serviceAvatar.type = AvatarTypes.ALL_MICRO_BLOGGING_BUDDY;
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
				serviceAvatar.avatar = avatarModel.getAvatar((fromThisUser) ? message.recipient : message.sender);
		}
		
	}
}