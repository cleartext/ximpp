package com.universalsprout.flex.components.list
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.core.Container;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.ResizeEvent;
	
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	
	public class SproutList extends Container
	{
		public function SproutList()
		{
			super();
			setStyle("verticalGap", 0);
		}
		
		public var animate:Boolean = true;
		public var virtualList:Boolean = true;
		
		protected var collection:ListCollectionView;
		protected var list:IList;
		public var itemRenderersByDataUid:Dictionary = new Dictionary();
	
		protected var resetItemRenderers:Boolean = true;
		
		protected var bottomOfListComponent:UIComponent;

		private var addingItem:Boolean = false;
		
		private var _itemRenderer:IFactory;
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer = value;
			resetItemRenderers = true;
			invalidateProperties();
			dispatchEvent(new Event("itemRendererChanged"));
		}
		
		//----------------------------------
		//  dataProvider
		//----------------------------------
		
		[Bindable("collectionChange")]
		[Inspectable(category="Data", defaultValue="undefined")]
		public function get dataProvider():ListCollectionView
		{
			return collection;
		}
		public function set dataProvider(value:ListCollectionView):void
		{
			if (collection)
			{
				collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
				collection.removeEventListener("listChanged", listChangedHandler);
			}
	
			if (value is Array)
			{
				collection = new ArrayCollection(value as Array);
			}
			else if (value is IList)
			{
				collection = new ListCollectionView(IList(value));
			}
			else if (value is XMLList)
			{
				collection = new XMLListCollection(value as XMLList);
			}
			else if (value is Dictionary)
			{
				var colTemp:ArrayCollection = new ArrayCollection();
				for each(var item:Object in Dictionary)
					colTemp.addItem(item);
				collection = colTemp;
			}
			else if (value is XML)
			{
				var xl:XMLList = new XMLList();
				xl += value;
				collection = new XMLListCollection(xl);
			}
			else
			{
				// convert it to an array containing this one item
				var tmp:Array = [];
				if (value != null)
					tmp.push(value);
				collection = new ArrayCollection(tmp);
			}
	
			collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
			collection.addEventListener("listChanged", listChangedHandler, false, 0, true);
			listChangedHandler(null);
	
			resetItemRenderers = true;
			invalidateProperties();
		}
		
		protected function listChangedHandler(event:Event):void
		{
			if(list)
				list.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
			
			list = collection.list;
			
			if(list)
				list.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
		}
	
		protected function collectionChangeHandler(event:CollectionEvent):void
		{
			if(event.kind == CollectionEventKind.RESET)
			{
				resetItemRenderers = true;
				invalidateProperties();
			}
			else
			{
				invalidateDisplayList();
			}
		}
				
		override protected function createChildren():void
		{
			super.createChildren();
			
			if(!bottomOfListComponent)
			{
				bottomOfListComponent = new UIComponent();
				bottomOfListComponent.graphics.beginFill(0xff0000);
				bottomOfListComponent.graphics.drawRect(0,0,10,10);
				bottomOfListComponent.visible = false;
				addChild(bottomOfListComponent);
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if(resetItemRenderers)
			{
				resetItemRenderers = false;
				
				for each(var item:ISproutListRenderer in itemRenderersByDataUid)
				{
					delete itemRenderersByDataUid[item.data.uid];
					item.removeEventListener(ResizeEvent.RESIZE, itemsResizeHandler);
					removeChild(item as DisplayObject);
				}
				
				invalidateDisplayList();
			}
		}
		
		protected function itemsResizeHandler(event:ResizeEvent):void
		{
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(addingItem)
				return;

			for each(item in itemRenderersByDataUid)
			{
				if(item.visible)// && !collection.contains(item.data))
				{
					item.setVisible(false, true);
					item.setIncludeInLayout(false, true);
				}
			}

			var itemWidth:Number = unscaledWidth - viewMetricsAndPadding.left - viewMetricsAndPadding.right;
			var extraRenderers:int = 5;

			var yCounter:Number = 0;
			var vGap:Number = getStyle("verticalGap");

			var childIndex:int = 0;
			addingItem = false;

			for each(var data:ISproutListData in collection)
			{
				var item:ISproutListRenderer = itemRenderersByDataUid[data.uid]; 
				
				if(!item)
				{
					item = itemRenderer.newInstance();
					item.data = data;
					item.addEventListener(ResizeEvent.RESIZE, itemsResizeHandler, false, 0, true);
					itemRenderersByDataUid[data.uid] = item;
					addChildAt(DisplayObject(item), childIndex);
					addingItem = true;
					callLater(function():void { addingItem = false; invalidateDisplayList()});
				}
				else
				{
					item.setVisible(true, true);
					item.setIncludeInLayout(true, true);
					setChildIndex(DisplayObject(item), childIndex);
				}

				childIndex++;

				if(animate && !addingItem)
					item.yTo = yCounter;
				else
					item.move(0, yCounter);
				
				yCounter += item.setWidth(itemWidth) + vGap;
				
				if(virtualList && (yCounter > verticalScrollPosition + unscaledHeight))
					extraRenderers--;

				if(extraRenderers < 1)
				{
					var estimatedHeight:Number = (yCounter+vGap)/childIndex * collection.length;
					bottomOfListComponent.includeInLayout = true;
					bottomOfListComponent.move(0, estimatedHeight-10);
					return;
				}
				
			}
			bottomOfListComponent.includeInLayout = false;
		}
	}
}