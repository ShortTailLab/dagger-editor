package
{
	public class Formation
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
		}
		
		public function remove(name:String):void
		{
			delete formations[name];
		}
		
		private function format(mats:Array):Array
		{
			var data:Array = new Array;
			var minX:Number = Number.MAX_VALUE;
			var minY:Number = Number.MIN_VALUE;
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