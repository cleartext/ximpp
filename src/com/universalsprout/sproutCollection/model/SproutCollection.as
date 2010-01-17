package com.universalSprout.sproutCollection.model
{
	import com.universalSprout.sproutCollection.SproutCollectionEvent;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;

	/**
	 * SproutCollection extends the ArrayCollection to provide three
	 * basic opperations,
	 *   Adding a new item
	 *   Editing an existing item
	 *   Deleting an item
	 */
	 
	public class SproutCollection extends ArrayCollection implements ISproutCollectionItem
	{

		/*
		 * The type of Object storred in this SproutCollection. SproutCollections can
		 * only store one type of Object and this must be an ISproutCollectionItem.
		 */
		public var type:Class;
		
		/*
		 * Has this collection been altered since it was last saved - have items, been
		 * added removed, or re-ordered.
		 */
		public var changedSinceLastSave:Boolean = false;
		
		/*
		 * If set, then when the index gets to the start, or the end of the collection
		 * it jumps to the other end.
		 */
		public var loop:Boolean = false;
		
		/*
		 * When me remove the selected item, do we want the internal index to decrement
		 */
		public var decrementOnDelete:Boolean = true;

		/*
		 * SproutCollection does not fully implement the name and id properties of
		 * ISproutCollectionItem.
		 */
		public function get name():String
		{
			return "SproutCollection";
		}
		public function set name(newName:String):void
		{
			throw new Error("you can not set the name property of a SproutCollection");
		}
		
		/*
		 * Constructor
		 */
		public function SproutCollection(type:Class, source:Object=null)
		{
			super();
			this.type = type;
			
			/*
			 * If there is a source object, then copy each item in that object
			 * into this SproutCollection.
			 */
			if(source)
			{
				//if source is not an ArrayCollection, returns null
				var tmpCollection:ArrayCollection = source as ArrayCollection;

				if(!tmpCollection)
				{
					/*
					 * If we have got here it probably means that source is
					 * the result from a HTTPService request. To get the 
					 * arrayCollection we have to select the property on the
					 * object proxy that should be the string returned by
					 * typeName()
					 */
					try
					{
						tmpCollection = source[typeName()] as ArrayCollection;
					}
					catch(error:Error){}
					
					/*
					 * If tempCollection is still null, it probably means
					 * that source is an ObjectProxy and there is only one
					 * element in the original array. Therefore, we need
					 * to create a new ISproutCollectionItem of type type
					 * and add that.
					 */
					if(!tmpCollection)
					{
						try
						{
							addItem(new type(source[typeName()]));
						}
						catch(error:Error)
						{
							/*
							 * If this still doesn't work then there is a
							 * problem with the source object.
							 */
							throw new Error("Error with source object: " + error.message);
						}
					}
				}
				
				/*
				 * Now that we have tmpCollection, add every item it 
				 * contains into this SproutCollection. If there was
				 * only one item, then tmpCollection will be null so 
				 * nothing will get added.
				 */
				for each(var item:Object in tmpCollection)
				{
					addItem(new type(item));
				}
			}
		}
		
		/*
		 * Index is the internal record of the selected item in the 
		 * ArrayCollection. -2 means that there is nothing selected.
		 *
		 * Here is where we check to keep 0 <= index < length we also
		 * use the loop setting to deal with what happens when the 
		 * index reaches its bounds.
		 * 
		 * If the index is changed, then dispatch a CURRENT_ITEM_CHANGED
		 * event.
		 */
		private var _index:int = -2;
		public function get index():int
		{
			return _index;
		}
		public function set index(newIndex:int):void
		{
			// if the collection is empty or if newIndex has an out
			// of bounds value, then set index to -2
			if(length==0 || newIndex<-2 || newIndex > length)
			{
				newIndex = -2;
			}
			
			// if we are beyond the start of the collection, then 
			// either go to the start or the end depending on loop
			else if(newIndex == -1)
			{
				newIndex = (loop) ? length-1 : 0;
			}

			// if we are past the end of the collection then either
			// go to the start, or to the end depending on loop
			else if(newIndex == length)
			{
				newIndex = (loop) ? 0 : length-1;
			}
			
			// set index
			_index = newIndex;
			
			dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.CURRENT_ITEM_CHANGED));
			dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE));
		}
		
		/*
		 * Return the currently selected item if any.
		 */
		public function get currentItem():ISproutCollectionItem
		{
			return (index < length && index >= 0) ? getItemAt(index) as ISproutCollectionItem : null;
		}
		/*
		 * This method checks if the new item is of the correct type
		 * then if it is not in the collection, adds it.
		 * Finally it sets the internal index to the item. This makes
		 * adding a new item to the collection very easy.
		 */
		public function set currentItem(newItem:ISproutCollectionItem):void
		{
			if(!(newItem is type))
			{
				throw new Error("new item is not of type " + type);
			}
			
			if(length==0 || !sourceArrayContains(newItem))
			{
				addItemAt(newItem, (index >= 0) ? index+1 : 0);
				dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.COLLECTION_CHANGED));
				changedSinceLastSave = true;
			}
			
			index = getItemIndex(newItem);
		}
		
		/*
		 * Tests if the given item is in the source array regardless of
		 * any sorts or filters applied.
		 */
		public function sourceArrayContains(item:ISproutCollectionItem):Boolean
		{
			return (list.getItemIndex(item) != -1);
		}
		
		/*
		 * Does what it says on the tin.
		 */
		public function deleteSelectedItem():void
		{
			if(currentItem)
			{
				removeItemAt(index);
				if(index == length || (decrementOnDelete && index != 0))
				{
					index--;
				}
				else
				{
					index = _index;
				}
				dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.COLLECTION_CHANGED));
				dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.DELETED_ITEM));
				changedSinceLastSave = true;
			}
		}
		
		public function deleteItem(item:ISproutCollectionItem):void
		{
			for(var i:int=0; i<length; i++)
			{
				if(item === getItemAt(i))
				{
					removeItemAt(i);
					if(index >= i)
					{
						_index--;
					}
					changedSinceLastSave = true;
					return;
				}
			}
			trace("can not delete '" + item.name + " - item not found");
		}
		
		public function getItemById(id:int):ISproutCollectionItemId
		{
			for(var i:int = list.length-1; i>=0; i--)
			{
				var item:ISproutCollectionItemId = list.getItemAt(i) as ISproutCollectionItemId;
				if(item.id == id)
					return item;
			}
			throw new Error("item with id: " + id + " not found.");
		}
		
		/*
		 * When we refresh after a filter or a sort, we should
		 * check that index is pointing to the same item it was
		 * pointing to before the sort or filter.
		 */
		override public function refresh():Boolean
		{
			// currentItem before refresh
			var previousCurrentItem:ISproutCollectionItem = currentItem;

			var result:Boolean = super.refresh();
			
			// find index after sort. getItemIndex() returns -1 if the
			// item is not found, but we want index to be -2 in this
			// case because setting index to -1 causes the index to be
			// 0 or to loop to the end of the index.
			var indexTmp:int =  getItemIndex(previousCurrentItem);
			index = (indexTmp == -1) ? -2 : indexTmp;
			return result;
		}
				
		/*
		 * When the view is displaying a new item that hasn't been added to
		 * the SproutCollection, we don't want the list to have a selected
		 * item, so we tell the list to display nothing and set the internal
		 * index to -2.
		 */
		public function nullCurrentItem():void
		{
			dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.SHOW_NULL_LIST_ITEM));
			_index = -2;
		}
		
		public function setItemIndex(item:ISproutCollectionItem, newIndex:int):void
		{
			var currentIndex:int = list.getItemIndex(item);

			if(newIndex < 0 || newIndex > length || newIndex == currentIndex)
				return;
			
			if(currentIndex == -1)
				throw new Error("item " + item.name + " not found in SproutCollection");
			else if(currentIndex == newIndex)
				return;
			
			list.removeItemAt(currentIndex);
			addItemAt(item, newIndex);
			
			if(currentIndex == index)
			{
				_index = newIndex;
			}
			else if(newIndex <= index && currentIndex > index)
			{
				_index++;
			}
			else if(newIndex >= index && currentIndex < index)
			{
				_index--;
			}

			dispatchEvent(new SproutCollectionEvent(SproutCollectionEvent.COLLECTION_CHANGED));
			changedSinceLastSave = true;
		}
		
		public function moveCurrentItemForward():void
		{
			setItemIndex(currentItem, index+1);
		}
		
		public function moveCurrentItemBack():void
		{
			setItemIndex(currentItem, index-1);
		}

		public function getIndexChanges():Array
		{
			var result:Array = new Array();
			for(var i:int = list.length-1; i>=0; i--)
			{
				result.push(list.getItemAt(i).id + "-" + i);
			}
			return result;
		}
		
		/*
		 * Find the simple string name of the ISproutCollectionItem
		 */
		public function typeName():String
		{
			var typeName:String = type.toString();
			typeName = typeName.substring(7, typeName.length-1);
			typeName = typeName.charAt(0).toLowerCase() + typeName.substr(1);
			return typeName;
		}
		
		public function sourceContains(item:ISproutCollectionItem):Boolean
		{
			for each(var sourceItem:ISproutCollectionItem in source)
			{
				if(sourceItem.compare(item))
					return true;
			}
			return false;
		}
		
		public function addNewItem(insertIndex:int=-2, selectNewItem:Boolean=true):void
		{
			var newItem:ISproutCollectionItem = new type();
			if(insertIndex == -2)
			{
				insertIndex = length;
			}
			addItemAt(newItem, insertIndex);
			if(selectNewItem)
			{
				currentItem = newItem;
			}
		}
		
		/*
		 * Export the collection and all its children as xml
		 */
		public function toXML():XML
		{
			var xml:XML = <s/>;
			xml.setName(typeName()+"s");
			for each(var item:ISproutCollectionItem in this)
			{
				xml.appendChild(item.toXML());
			}
			return xml;
		}
		
		/*
		 * compare each of the elements in the two SproutCollections
		 * compare the list items to ignore any sorting or filtering.
		 */ 
		public function compare(value:ISproutCollectionItem):Boolean
		{
			var testCollection:SproutCollection = value as SproutCollection;
			
			if(!testCollection)
				return false;
			if(testCollection.list.length != list.length)
				return false;
			if(testCollection.name != name)
				return false; // name should be the same, but just in case.

			for(var i:int=list.length-1; i>=0; i--)
			{
				var thisItem:ISproutCollectionItem = list.getItemAt(i) as ISproutCollectionItem;
				var testItem:ISproutCollectionItem = testCollection.list.getItemAt(i) as ISproutCollectionItem;
				if(!thisItem.compare(testItem))
					return false;
			}
			return true;
		}
	}
}