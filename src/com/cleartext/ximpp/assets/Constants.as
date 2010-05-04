package com.cleartext.ximpp.assets
{
	import flash.display.BitmapData;
	
	public class Constants
	{
		/**
		 * CONSTANTS TO CHANGE
		 */
		
		// default 0xf7a136
		public static const THEME_COLOUR:uint = 0xf7a136;
		// default 0x000000
		public static const BACKGROUND_COLOUR:uint = 0x000000;
		// default 0x3e443f
		public static const BACKGROUND_ACCENT:uint = 0x3e443f;
		
		// default com/cleartext/ximpp/assets/logo.png ideal height: 30 px
		[Embed (source="com/cleartext/ximpp/assets/logo.png")]
		public static const Logo:Class;
		
		/**
		 * CONSTANTS NOT TO CHANGE
		 */
		
		public static const TOP_BAR_HEIGHT:Number = 88;
		public static const TOP_ROW_HEIGHT:Number = 25;
		public static const AVATAR_TAB_HEIGHT:Number = 65;

		[Embed (source="/com/cleartext/ximpp/assets/closeUp.png")]
		public static const CloseUp:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/closeOver.png")]
		public static const CloseOver:Class;

		[Embed (source="/com/cleartext/ximpp/assets/defaultGroup.png")]
		public static const DefaultGroupIcon:Class;

		[Embed (source="/com/cleartext/ximpp/assets/timeUp.png")]
		public static const TimeUp:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/timeSelected.png")]
		public static const TimeSelected:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/abcUp.png")]
		public static const AbcUp:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/abcSelected.png")]
		public static const AbcSelected:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/statusUp.png")]
		public static const StatusUp:Class;
		
		[Embed (source="/com/cleartext/ximpp/assets/statusSelected.png")]
		public static const StatusSelected:Class;
			
		[Embed (source="com/cleartext/ximpp/assets/send.png")]
		public static const SendUp:Class;
			
		[Embed (source="com/cleartext/ximpp/assets/sendDown.png")]
		public static const SendDown:Class;
			
		[Embed (source="com/cleartext/ximpp/assets/sendDisabled.png")]
		public static const SendDisabled:Class;
			
		[Embed (source="com/cleartext/ximpp/assets/help.png")]
		public static const HelpUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/helpOver.png")]
		public static const HelpOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/preferences.png")]
		public static const PreferencesUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/preferencesOver.png")]
		public static const PreferencesOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/console.png")]
		public static const ConsoleUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/consoleOver.png")]
		public static const ConsoleOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/allSocial.png")]
		public static const AllSocial:Class;

		[Embed (source="com/cleartext/ximpp/assets/allBuddies.png")]
		public static const AllBuddies:Class;

		[Embed (source="com/cleartext/ximpp/assets/gateway.png")]
		public static const Gateways:Class;

		[Embed (source="com/cleartext/ximpp/assets/noGroup.png")]
		public static const NoGroup:Class;

		[Embed (source="com/cleartext/ximpp/assets/add.png")]
		public static const Add:Class;

		[Embed (source="com/cleartext/ximpp/assets/addOver.png")]
		public static const AddOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/replyUp.png")]
		public static const ReplyUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/replyOver.png")]
		public static const ReplyOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/retweetUp.png")]
		public static const RetweetUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/retweetOver.png")]
		public static const RetweetOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/deleteUp.png")]
		public static const DeleteUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/deleteOver.png")]
		public static const DeleteOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/directMessageUp.png")]
		public static const DirectMessageUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/directMessageOver.png")]
		public static const DirectMessageOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/atUp.png")]
		public static const AtUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/atOver.png")]
		public static const AtOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/success.png")]
		public static const Sucess:Class;

		[Embed (source="com/cleartext/ximpp/assets/error.png")]
		public static const Error:Class;

		[Embed (source="com/cleartext/ximpp/assets/pending.png")]
		public static const Pending:Class;

		[Embed (source="com/cleartext/ximpp/assets/isTyping.png")]
		public static const IsTyping:Class;

		[Embed (source="com/cleartext/ximpp/assets/editUp.png")]
		public static const EditUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/editOver.png")]
		public static const EditOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/addBuddyUp.png")]
		public static const AddBuddyUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/addBuddyOver.png")]
		public static const AddBuddyOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/addGatewayUp.png")]
		public static const AddGatewayUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/addGatewayOver.png")]
		public static const AddGatewayOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/getSatisfaction.png")]
		public static const GetSatisfactionUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/getSatisfactionOver.png")]
		public static const GetSatisfactionOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/searchUp.png")]
		public static const SearchUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/searchOver.png")]
		public static const SearchOver:Class;

		[Embed (source="com/cleartext/ximpp/assets/tabs.png")]
		public static const Tabs:Class;

		[Embed (source="com/cleartext/ximpp/assets/unreadUp.png")]
		public static const UnreadUp:Class;

		[Embed (source="com/cleartext/ximpp/assets/unreadSelected.png")]
		public static const UnreadSelected:Class;

		[Embed (source="/com/cleartext/ximpp/assets/user.jpg")]
		public static const DefaultAvatar:Class;

		[Embed (source="/com/cleartext/ximpp/assets/edit.png")]
		public static const EditIcon:Class;
		
		public static const defaultAvatarBmd:BitmapData = new DefaultAvatar().bitmapData;

		public static const editIconBmd:BitmapData = new EditIcon().bitmapData;

	}
}