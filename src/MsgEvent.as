package
{
	import flash.events.Event;
	
	public class MsgEvent extends Event
	{
		static public var POS_CHANGE:String = "x_change";
		static public var ADD_FORMATION:String = "add_formation";
		static public var REMOVE_FORMATION:String = "remove_formation";
		static public var RENAME_LEVEL:String = "rename_level";
		public var hintMsg:String = "";
		
		public function MsgEvent(type:String, msg:String = "")
		{
			super(type);
			hintMsg = msg;
		}
	}
}