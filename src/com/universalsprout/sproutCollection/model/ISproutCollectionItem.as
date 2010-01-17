package com.universalSprout.sproutCollection.model
{
	
	/**
	 * Interface to control the type of objects that can be added to a
	 * SproutCollection. Each item should have a name property
	 * 
	 * All ISproutCollectionItem Constructors should be able to accept
	 * an ISproutCollectionItem of the same type and clone that object.
	 * For example:
	 * 
	 * var obj1:SproutCollectionItem = new SproutCollectionItem();
	 * var obj2:SproutCollectionItem = new SproutCollectionItem(obj1);
	 * 
	 * obj2 is now a DEEP copy of obj1
	 * 
	 * To allow this, all properties of an ISproutCollectionItem must
	 * be either primitives or SproutCollections.
	 */

	public interface ISproutCollectionItem
	{
		function get name():String;
		function set name(value:String):void;
		
		function toXML():XML;
		
		function compare(value:ISproutCollectionItem):Boolean;
	}
}