package
{
	import flash.events.Event;
	
	public class MsgEvent extends Event
	{
		static public var POS_CHANGE:String = "x_change";
		
		public function MsgEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}