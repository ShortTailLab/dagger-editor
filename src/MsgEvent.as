package
{
	import flash.events.Event;
	
	public class MsgEvent extends Event
	{
		static public var POS_CHANGE:String = "x_change";
		static public var ADD_FORMATION:String = "add_formation";
		static public var REMOVE_FORMATION:String = "remove_formation";
		static public var RENAME_LEVEL:String = "rename_level";
		static public var EXEC_TYPE:String = "exec_type";
		static public var EDIT_PATH:String = "edit_path";
		public var hintMsg:String = "";
		public var hintData:*;
		
		public function MsgEvent(type:String, msg:String = "")
		{
			super(type);
			hintMsg = msg;
		}
	}
}