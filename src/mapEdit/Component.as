package mapEdit
{
	import flash.events.Event;
	import flash.geom.Point;
	
	import spark.core.SpriteVisualElement;
	public class Component extends SpriteVisualElement
	{
		public var sid:String = "";
		public var type:String;
		public var triggerTime:int = -1;
		public var mIsSelected:Boolean = false;
		public var triggerId:String = "";
		protected var editView:MainScene = null;
		
		public function Component(_editView:MainScene = null, type:String = "")
		{
			super();
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
		
		public function initFromData(data:Object):void{}
		public function toExportData():Object{return null;}
	}
}