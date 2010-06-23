package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.events.ApplicationEvent;
	import com.cleartext.ximpp.events.HasAvatarEvent;
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.models.ChatModel;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.ChatRoom;
	import com.cleartext.ximpp.models.valueObjects.IBuddy;
	import com.cleartext.ximpp.models.valueObjects.Status;
	import com.cleartext.ximpp.views.common.Avatar;
	import com.cleartext.ximpp.views.common.StatusIcon;
	import com.cleartext.ximpp.views.common.UnreadMessageBadge;
	import com.universalsprout.flex.components.list.SproutListRendererBase;
	
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.UITextField;
	import mx.effects.Tween;
	
	import org.swizframework.Swiz;

	public class BuddyRenderer extends SproutListRendererBase
	{
		[Autowire]
		public var chats:ChatModel;
		
		[Autowire]
		public var xmpp:XMPPModel;
		
		private static const SMALL_HEIGHT:Number = 40;
		private static const BIG_HEIGHT:Number = 46;
		private static const AVATAR_SIZE:Number = 32;
		private static const LEFT_PADDING:Number = 3;

		private static const PADDING:Number = 3;
		
		private var previousStatus:String = Status.OFFLINE;
		private var over:Boolean = false;
		
		private var customContextMenu:ContextMenu;
		private var subscribeItem:ContextMenuItem;
		private var logonItem:ContextMenuItem;
		private var timerCount:int=0;
		
		//---------------------------------------
		// Constructor
		//---------------------------------------
		
		public function BuddyRenderer(initialWidth:Number=NaN, initialHeight:Number=NaN)
		{
			super(initialWidth, SMALL_HEIGHT);
			heightTo = SMALL_HEIGHT;
			cacheAsBitmap = true;
			doubleClickEnabled = true;
			addEventListener(MouseEvent.DOUBLE_CLICK,
				function():void
				{
					chats.getChat(buddy, true);
					
					var chatRoom:ChatRoom = buddy as ChatRoom;
					if(chatRoom && xmpp.connected && chatRoom.status.isOffline())
						xmpp.joinChatRoom(chatRoom.jid, chatRoom.ourNickname, chatRoom.password);
				});
			addEventListener(MouseEvent.ROLL_OUT,
				function():void
				{
					over = false;
					invalidateProperties();
					invalidateDisplayList();
				});
			addEventListener(MouseEvent.ROLL_OVER,
				function():void
				{
					over = true;
					nameLabel.styleName = "blackBold";
					invalidateDisplayList();
				});

		}
		
		[Mediate(event="ApplicationEvent.STATUS_TIMER")]
		public function statusTimerHandler(event:ApplicationEvent):void
		{
			if(!buddy.status.isOffline())
			{
				timerCount++;
				invalidateProperties();
			}
		}
		
		private function createContextMenu(event:Event):void
		{
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
				return;

			var subscribedTo:Boolean = (buddy is Buddy) && (buddy as Buddy).subscribedTo;
			
			// label at top
			customContextMenu.getItemAt(0).label = (buddy && xmpp.connected) ? buddy.nickname : "go online to edit";
			// workstream label
			customContextMenu.getItemAt(3).label = buddy.isMicroBlogging ? "remove from workstream" : "add to workstream";
			
			
			// add or remove subscription request if required
			if(!subscribedTo && !subscribeItem)
			{
				subscribeItem = new ContextMenuItem("resend subscription request", true);
				subscribeItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, sendSubscription);
				customContextMenu.addItemAt(subscribeItem, 4);
			}
			else if(subscribedTo && subscribeItem)
			{
				customContextMenu.removeItem(subscribeItem);
				subscribeItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, sendSubscription);
				subscribeItem = null;
			}
			
			// add or remove gateway item if required
			if(buddy.isGateway && buddy.status.isOffline() && !logonItem)
			{
				logonItem = new ContextMenuItem("logon", true);
				logonItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, logonHandler);
				customContextMenu.addItem(logonItem);
			}
			else if((buddy.isGateway || !buddy.status.isOffline()) && logonItem)
			{
				customContextMenu.removeItem(logonItem);
				logonItem.removeEventListener(ContextMenuEvent.MENU_ITEM_SELECT, logonHandler);
				logonItem = null;
			}
			
			// set enabled based on connected status
			for(var i:int=1; i<customContextMenu.numItems; i++)
			{
				customContextMenu.getItemAt(i).enabled = xmpp.connected;
			}
		}
		
		private function logonHandler(event:ContextMenuEvent):void
		{
			// incase we went offline while the user was clicking
			if(!xmpp.connected)
				return;
			xmpp.sendPresence(buddy.jid);
		}

		private function sendSubscription(event:ContextMenuEvent):void
		{
			// incase we went offline while the user was clicking
			if(!xmpp.connected)
				return;
			xmpp.sendSubscribe(buddy.jid, SubscriptionTypes.SUBSCRIBE);
		}

		private function editHandler(event:ContextMenuEvent):void
		{
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.EDIT_BUDDY_WINDOW);
			popupEvent.buddy = buddy;
			Swiz.dispatchEvent(popupEvent);
		}

		private function socialHandler(event:ContextMenuEvent):void
		{
			// incase we went offline while the user was clicking
			// plus we only want to make Buddies microblogging buddies
			if(!xmpp.connected || !(buddy is Buddy))
				return;
				
			buddy.isMicroBlogging = !buddy.isMicroBlogging;
			xmpp.modifyRosterItem(buddy);
		}

		private function deleteHandler(event:ContextMenuEvent):void
		{
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.DELETE_BUDDY_WINDOW);
			popupEvent.buddy = buddy;
			Swiz.dispatchEvent(popupEvent);
		}

		private function get buddy():IBuddy
		{
			return data as IBuddy;
		}
		
		override public function set data(value:Object):void
		{
			if(data == value)
				return;

			if(buddy)
				buddy.removeEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangedHandler);
			
			super.data = value;

			if(buddy)
			{
				buddy.addEventListener(HasAvatarEvent.CHANGE_SAVE, buddyChangedHandler);
				if(avatar)
					avatar.data = buddy;

				customContextMenu = new ContextMenu();
				customContextMenu.hideBuiltInItems();
				contextMenu = customContextMenu;
				
				if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
				{
					customContextMenu.items.push(new ContextMenuItem("Can not edit My Workstream", false, false));
				}
				else
				{
					addEventListener(MouseEvent.CONTEXT_MENU, createContextMenu);
	
					var objs:Array = [
						{label: '', handler: null, separatorBefore: false},
						{label: 'edit', handler: editHandler, separatorBefore: true},
						{label: 'delete', handler: deleteHandler, separatorBefore: false},
						{label: 'add to workstream', handler: socialHandler, separatorBefore: true}
						];
						
					for each(var obj:Object in objs)
					{
						var item:ContextMenuItem = new ContextMenuItem(obj.label, obj.separatorBefore, false);
						if(obj.handler)
							item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, obj.handler);
						customContextMenu.addItem(item);
					}
				}
			}
			
			buddyChangedHandler(null);
		}
		
		private function buddyChangedHandler(event:HasAvatarEvent):void
		{
			if(!buddy || buddy.status.isOffline())
			{
				timerCount = 0;
				previousStatus = Status.OFFLINE;
			}
			else if(buddy.status.value != previousStatus)
			{
				timerCount = 0;
				previousStatus = buddy.status.value;
			}
			
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
		private var unreadMessageBadge:UnreadMessageBadge;
		
		//---------------------------------------
		// Create Children
		//---------------------------------------
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!avatar)
			{
				avatar = new Avatar();
				avatar.x = LEFT_PADDING;
				avatar.y = PADDING;
				avatar.width = AVATAR_SIZE;
				avatar.height = AVATAR_SIZE;
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
				nameLabel.x = AVATAR_SIZE + PADDING + LEFT_PADDING;
				nameLabel.y = PADDING;
				addChild(nameLabel);
			}

			if(!statusLabel)
			{
				statusLabel = new UITextField();
				statusLabel.styleName = "lGreySmall";
				statusLabel.x = AVATAR_SIZE + PADDING + LEFT_PADDING;
				statusLabel.y = 16;
				addChild(statusLabel);
			}
			
			if(!customStatusLabel)
			{
				customStatusLabel = new UITextField();
				customStatusLabel.styleName = "lGreySmall";
				customStatusLabel.x = AVATAR_SIZE + PADDING + LEFT_PADDING;
				customStatusLabel.y = 29;
				customStatusLabel.visible = false;
				addChild(customStatusLabel);
			}

			if(!unreadMessageBadge)
			{
				unreadMessageBadge = new UnreadMessageBadge();
				unreadMessageBadge.y = 12;
				unreadMessageBadge.alpha = 0.7;
				unreadMessageBadge.visible = false;
				addChild(unreadMessageBadge);
			}
		}
		
		//---------------------------------------
		// Commit Properties
		//---------------------------------------
		
		override protected function commitProperties():void
		{
			super.commitProperties();

			if(!buddy)
				return;
	
			// set values
			customStatusLabel.text = buddy.customStatus;
			nameLabel.text = buddy.nickname;
			statusIcon.status.value = buddy.status.value;
			if(unreadMessageBadge.count != buddy.unreadMessages)
			{
				unreadMessageBadge.count = buddy.unreadMessages;
				callLater(invalidateProperties);
			}
			
			if(buddy.status.isOffline())
			{
				statusLabel.text = buddy.status.value;
			}
			else
			{
				var extraText:String = " for ";
				var mins:int = timerCount;
				
				if(mins == 0)
					extraText += "< 1 minute";
				else if(mins < 5)
					extraText += "a few minutes";
				else if(mins < 60)
					extraText += mins + " minutes";
				else if(mins < 1440)
					extraText += Math.floor(mins/60) + " hours";
				else
					extraText += Math.floor(mins/1400) + " days";
				
				statusLabel.text = buddy.status.value + extraText;
			}
			
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
			
			if(buddy.status.isOffline())
			{
				nameLabel.styleName = "lGreyBold";
				avatar.alpha = 0.5;
				alpha = 0.6;
			} 
			else
			{
				nameLabel.styleName = "dGreyBold";
				avatar.alpha = 1;
				alpha = 1;
			}
			
			statusIcon.x = width - 2*PADDING - StatusIcon.SIZE;
			unreadMessageBadge.x = width - 3*PADDING - unreadMessageBadge.width - StatusIcon.SIZE;
			
			var maxWidth:Number = width - AVATAR_SIZE - StatusIcon.SIZE - 4*PADDING - LEFT_PADDING;
			nameLabel.setActualSize(maxWidth, nameLabel.textHeight);

			customStatusLabel.setActualSize(maxWidth, customStatusLabel.textHeight);
			customStatusLabel.truncateToFit();

			statusLabel.setActualSize(maxWidth, statusLabel.textHeight);
		}

		override public function setWidth(widthVal:Number):Number
		{
			width = widthVal;
			return heightTo;
		}
		
		//---------------------------------------
		// Update Display List
		//---------------------------------------
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			statusIcon.visible = !over;
			
			var g:Graphics = graphics;
			g.clear();

			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(unscaledWidth, unscaledHeight, Math.PI/2);
			
			if(over)
				g.beginFill(0xffffff, 1);
			else
				g.beginGradientFill(GradientType.LINEAR, [0xffffff, 0xdedede], [0.5, 0.5], [95, 255], matrix);
			
			g.drawRect(0, 0, unscaledWidth, unscaledHeight);
			
			// arrow
			if(over)
			{
				var xVal:Number = unscaledWidth - StatusIcon.SIZE + 2;
				g.lineStyle(3.5, 0x585858, 0.75)
				g.moveTo(xVal, 15);
				g.lineTo(xVal + 5, 19);
				g.lineTo(xVal, 23);
				g.lineStyle();
			}
			
			// bottom line
			if(over || buddy && !buddy.status.isOffline())
			{
				g.beginFill(0x000000, 0.15)
				g.drawRect(0, unscaledHeight-1, unscaledWidth, 1);
			}
		}
	}		
}