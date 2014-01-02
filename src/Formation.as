package
{
	import flash.events.EventDispatcher;

	public class Formation extends EventDispatcher
	{
		public  var formations:Object;
		
		private static var instance:Formation = null;
		public static function getInstance():Formation
		{
			if(!instance)
				instance = new Formation;
			return instance;
		}
		
		public function Formation()
		{
			formations = new Object;
		}
		
		public function add(name:String, mats:Array):void
		{
			formations[name] = format(mats);
			this.dispatchEvent(new MsgEvent(MsgEvent.ADD_FORMATION, name));
		}
		
		public function remove(name:String):void
		{
			delete formations[name];
		}
		
		private function format(mats:Array):Array
		{
			var data:Array = new Array;
			var minX:Number = mats[0].x;
			var minY:Number = mats[0].y;
			for each(var m:MatSprite in mats)
			{
				minX = Math.min(m.x, minX);
				minY = Math.max(m.y, minY);
				
				var point:Object = new Object;
				point.x = m.x;
				point.y = m.y;
				data.push(point);
			}
			for each(var p in data)
			{
				p.x -= minX;
				p.y -= minY;
			}
			return data;
		}
	}
}