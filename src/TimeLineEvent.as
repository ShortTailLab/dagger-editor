package
{
	import flash.events.Event;
	
	public class TimeLineEvent extends Event
	{
		public var data:Object;
		
		public function TimeLineEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			data = new Object;
			data.x = 0;
			data.y = 0;
		}
	}
}