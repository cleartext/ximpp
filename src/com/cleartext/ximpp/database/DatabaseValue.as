package com.cleartext.ximpp.database
{
	import flash.data.SQLStatement;
	

	public class DatabaseValue
	{
		public var columnName:String;
		public var value:Object;
		public var match:Boolean;
		public function get param():String
		{
			return ":" + columnName;
		}
		
		
		public function DatabaseValue(columnName:String, value:Object, match:Boolean=true)
		{
			this.columnName = columnName;
			this.value = (value == null) ? "" : value;
			this.match = match;
		}

		public function setParameter(stmt:SQLStatement):String
		{
			var count:int = 0;
			var paramString:String = ":" + columnName;

			while(stmt.parameters[paramString + count] != null)
			{
				count++;
			} 
			
			paramString += count;
			
			stmt.parameters[paramString] = value;
			return columnName + ((match) ? " = " : " != ") + paramString;
		}
	}
	
}