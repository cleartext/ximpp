package com.cleartext.ximpp.views.buddies
{
	import com.cleartext.ximpp.events.BuddyEvent;
	import com.cleartext.ximpp.events.ChatEvent;
	import com.cleartext.ximpp.events.PopUpEvent;
	import com.cleartext.ximpp.models.ApplicationModel;
	import com.cleartext.ximpp.models.XMPPModel;
	import com.cleartext.ximpp.models.types.SubscriptionTypes;
	import com.cleartext.ximpp.models.valueObjects.Buddy;
	import com.cleartext.ximpp.models.valueObjects.Chat;
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
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	
	import mx.core.IInvalidating;
	import mx.core.UITextField;
	import mx.effects.Tween;
	
	import org.swizframework.Swiz;

	public class BuddyRenderer extends SproutListRendererBase
	{
		[Autowire]
		public var appModel:ApplicationModel;
		
		[Autowire]
		public var xmpp:XMPPModel;
		
		private static const SMALL_HEIGHT:Number = 40;
		private static const BIG_HEIGHT:Number = 46;
		private static const AVATAR_SIZE:Number = 32;
		private static const LEFT_PADDING:Number = 3;

		private static const PADDING:Number = 3;
		
		private var previousStatus:String = Status.OFFLINE;
		private var statusTimer:Timer;
		private var over:Boolean = false;
		
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
					var chat:Chat = appModel.getChat(buddy);
					Swiz.dispatchEvent(new ChatEvent(ChatEvent.SELECT_CHAT, chat));
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

			contextMenuLabel = new ContextMenuItem("");
			contextMenuLabel.enabled = false;
			
			editItem = new ContextMenuItem("edit");
			editItem.separatorBefore = true;
			editItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, editHandler);
			
			deleteItem = new ContextMenuItem("delete");
			deleteItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, deleteHandler);
			
			socialItem = new ContextMenuItem("");
			socialItem.separatorBefore = true;
			socialItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, socialHandler);
			
			var customContextMenu:ContextMenu = new ContextMenu();
			customContextMenu.hideBuiltInItems();
			customContextMenu.customItems.push(contextMenuLabel);
			customContextMenu.customItems.push(editItem);
			customContextMenu.customItems.push(deleteItem);
			customContextMenu.customItems.push(socialItem);
			
			customContextMenu.addEventListener(Event.DISPLAYING, displayContextMenu);
			
			contextMenu = customContextMenu;
			
			statusTimer = new Timer(60000);
			statusTimer.addEventListener(TimerEvent.TIMER, statusTimerHandler);
		}
		
		private function statusTimerHandler(event:TimerEvent):void
		{
			invalidateProperties();
		}
		
		private function displayContextMenu(event:Event):void
		{
			if(buddy == Buddy.ALL_MICRO_BLOGGING_BUDDY)
			{
				contextMenuLabel.label = "can not edit";
				if(contextMenu.containsItem(editItem))
					contextMenu.removeItem(editItem);
				deleteItem.enabled = false;
				socialItem.enabled = false;
				return;
			}
			
			contextMenuLabel.label = (buddy && xmpp.connected) ? buddy.nickName : "go online to edit";
			socialItem.label = (buddy && buddy.microBlogging) ? "remove from workstream" : "add to workstream";
			
			var customContextMenu:ContextMenu = (contextMenu as ContextMenu);
			
			if(!buddy.subscribedTo && customContextMenu.customItems.length == 4)
			{
				var subscirbeItem:ContextMenuItem = new ContextMenuItem("resend subscirption request", true);
				subscirbeItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
					function():void
					{
						xmpp.sendSubscribe(buddy.jid, SubscriptionTypes.SUBSCRIBE);
						subscirbeItem.caption = "subscription request sent";
						subscirbeItem.enabled = false;
					});
				customContextMenu.customItems.push(subscirbeItem);
			}
			else if(buddy.subscribedTo && customContextMenu.customItems.length == 5)
			{
				customContextMenu.customItems.pop();
			}
			
			editItem.enabled = xmpp.connected;
			deleteItem.enabled = xmpp.connected;
			socialItem.enabled = xmpp.connected;
		}

		private function editHandler(event:ContextMenuEvent):void
		{
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.EDIT_BUDDY_WINDOW);
			popupEvent.buddy = buddy;
			Swiz.dispatchEvent(popupEvent);
		}

		private function socialHandler(event:ContextMenuEvent):void
		{
			buddy.microBlogging = !buddy.microBlogging;
			xmpp.modifyRosterItem(buddy);
		}

		private function deleteHandler(event:ContextMenuEvent):void
		{
			var popupEvent:PopUpEvent = new PopUpEvent(PopUpEvent.DELETE_BUDDY_WINDOW);
			popupEvent.buddy = buddy;
			Swiz.dispatchEvent(popupEvent);
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
			
			buddyChangedHandler(null);
		}
		
		private function buddyChangedHandler(event:BuddyEvent):void
		{
			if(!buddy || buddy.status.isOffline())
			{
				statusTimer.reset();
				previousStatus = Status.OFFLINE;
			}
			else if(buddy.status.value != previousStatus)
			{
				statusTimer.reset();
				statusTimer.start();
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
		
		private var contextMenuLabel:ContextMenuItem;
		private var editItem:ContextMenuItem;
		private var deleteItem:ContextMenuItem;
		private var socialItem:ContextMenuItem;
		
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
			nameLabel.text = buddy.nickName;
			statusIcon.status.value = buddy.status.value;
			if(unreadMessageBadge.count != buddy.unreadMessageCount)
			{
				unreadMessageBadge.count = buddy.unreadMessageCount;
				callLater(invalidateProperties);
			}
			
			if(buddy.status.isOffline())
			{
				statusLabel.text = buddy.status.value;
			}
			else
			{
				var extraText:String = " for ";
				var mins:int = statusTimer.currentCount;
				
				if(mins == 0)
					extraText += " < 1 minute";
				else if(mins == 1)
					extraText += " 1 minute";
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