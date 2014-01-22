package editEntity
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	
	public class EditBase extends Sprite
	{
		public var id:String = "";
		public var type:String;
		public var triggerTime:int = -1;
		public var isSelected:Boolean = false;
		public var triggerId:String = "";
		protected var editView:EditView = null;
		
		public function EditBase(_editView:EditView = null, type:String = "")
		{
			this.editView = _editView;
			this.type = type;
		}
		
		public function select(value:Boolean):void{}
		public function update():void{};
		
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
		
		public function onDelete():void{}
		
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