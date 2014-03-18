/*
阵型

*/

package formationEdit
{
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mapEdit.EntityComponent;

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
			var file:File = File.desktopDirectory.resolvePath("editor/formations.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				formations = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
				formations = new Object;
		}
		public function hasFormation(name:String):Boolean
		{
			return formations.hasOwnProperty(name);
		}
		
		public function add(name:String, mats:Array):void
		{
			if(!formations.hasOwnProperty(name))
			{
				formations[name] = format(mats);
				save();
				this.dispatchEvent(new MsgEvent(MsgEvent.ADD_FORMATION, name));
			}
			else
				throw new Error("name is invalid!");
		}
		
		public function rename(from:String, to:String):void
		{
			if(from != to)
			{
				if(!this.hasFormation(from))
					throw new Error("from is invalid!");
				else if(this.hasFormation(to))
					throw new Error("to has exsited!");
				else
				{
					formations[to] = formations[from];
					delete formations[from];
				}
			}
		}
		
		public function remove(name:String):void
		{
			if(this.hasFormation(name))
			{
				delete formations[name];
				save();
			}
			else
				throw new Error("trying to remove a unexist formatiom!");
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
			for each(var m:EntityComponent in mats)
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