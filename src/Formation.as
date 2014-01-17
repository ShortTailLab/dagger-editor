package
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import editEntity.MatSprite;

	public class Formation extends EventDispatcher
	{
		public  var formations:Object;
		private var numCount:int = 0;
		
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
			var file:File = File.desktopDirectory.resolvePath("editor/formations.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				var data:Object = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				for each(var item in data)
				{
					var arr:Array = new Array;
					for each(var p in item)
						arr.push(p);
					formations[getName()] = arr;
				}
			}
			
		}
		
		public function add(mats:Array):void
		{
			var name:String = getName();
			formations[name] = format(mats);
			save();
			
			this.dispatchEvent(new MsgEvent(MsgEvent.ADD_FORMATION, name));
		}
		
		public function remove(name:String):void
		{
			delete formations[name];
			save();
			this.dispatchEvent(new MsgEvent(MsgEvent.REMOVE_FORMATION));
		}
		
		public function save():void
		{
			var file:File = File.desktopDirectory.resolvePath("editor/formations.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(formations));
			stream.close();
		}
		
		private function getName():String
		{
			return "f"+(numCount++);
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