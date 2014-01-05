package
{
	import flash.events.Event;
	
	public class MsgEvent extends Event
	{
		static public var POS_CHANGE:String = "x_change";
		static public var ADD_FORMATION:String = "add_formation";
		public var hintMsg:String = "";
		
		public function MsgEvent(type:String, msg:String = "")
		{
			super(type);
			hintMsg = msg;
		}
	}
}