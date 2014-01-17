package editEntity
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class EditBase extends Sprite
	{
		public var id:int;
		public var type:String;
		public var triggerTime:int = -1;
		public var isSelected:Boolean = false;
		
		public function EditBase()
		{
		}
		
		public function select(value:Boolean):void
		{
			
		}
		
		public function trim(size:Number):void{}
		
		public function enablePosChangeDispatch(value:Boolean):void
		{
			if(value)
			{
				posRecord = new Point(x, y);
				this.addEventListener(Event.ENTER_FRAME, onPosCheck);
			}
			else 
				this.removeEventListener(Event.ENTER_FRAME, onPosCheck);
		}
		
		private var posRecord:Point;
		private function onPosCheck(e:Event):void
		{
			if(posRecord.x != x || posRecord.y != y)
				this.dispatchEvent(new MsgEvent(MsgEvent.POS_CHANGE));
			posRecord.x = x;
			posRecord.y = y;
		}
		
		public function initFromData(data:Object):void
		{
		}
		
		public function toExportData():Object
		{
			return null;
		}
	}
}