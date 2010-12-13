package com.cleartext.esm.models.types
{
	import mx.collections.ArrayCollection;

	public class AvatarDisplayTypes
	{
		public static const AVATAR:String = "profile pic";
		public static const NICKNAME:String = "nickname";
		public static const BOTH:String = "both";
		
		public static const TYPES:ArrayCollection = new ArrayCollection([AVATAR, NICKNAME, BOTH]);
	}
}