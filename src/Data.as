package
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.controls.Alert;
	
	public class Data extends EventDispatcher
	{
		public var matsData:Object = null;
		public var enemyData:Object = null;
		public var enemyMoveData:Object = null;
		public var displayData:Object = null;
		public var levelXML:XML = null;
		
		private var _excelReader:ExcelReader;
		private static var instance:Data = null;
		public static function getInstance():Data
		{
			if(!instance)
				instance = new Data;
			return instance;
		}
		
		public function Data(target:IEventDispatcher=null)
		{
			super(target);
			
			matsData = new Object;
			
		}
		
		public function init():void
		{
			var file:File = File.desktopDirectory.resolvePath("data.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				displayData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else 
			{
				displayData = new Array;
				var level:Object = new Object;
				level.levelName = "level1";
				level.endTime = 0;
				level.data = new Array;
				displayData.push(level);
			}
			levelXML = parseLevelXML(displayData);
			
			file = File.desktopDirectory.resolvePath("enemyMoveData.json");
			if(file.exists)
			{
				stream = new FileStream;
				stream.open(file, FileMode.READ);
				enemyMoveData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
				enemyMoveData = new Object;
			
			_excelReader = new ExcelReader();
			_excelReader.init(onDataComplete);
		}
		private function onDataComplete():void
		{
			// do sth.
			enemyData = _excelReader.enemyData
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function saveLocal():void
		{
			var file:File = File.desktopDirectory.resolvePath("data.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(displayData));
			stream.close();
			
			file = File.desktopDirectory.resolvePath("enemyMoveData.json");
			stream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(enemyMoveData));
			stream.close();
		}
		
		public function exportJS():void
		{
			for(var type in enemyMoveData)
			{
				enemyData[type]["move_type"] = enemyMoveData[type]["move_type"];
				enemyData[type]["move"] = enemyMoveData[type]["move"];
			}
			
			var source:Array = displayData[0].data;
			var positions:Array = new Array;
			for each(var item:Object in source)
			{
				var data:Object = new Object;
				data.type = item.type;
				data.x = item.x;
				data.y = item.y;
				positions.push(data);
			}
			var exportData:Object = new Object();
			exportData["pos"] = positions;
			if (enemyData) {
				exportData["defs"] = enemyData;
			}
			
			var js:String = "module('level_data', function(){ var Level = {};Level.demo = "+
				""+JSON.stringify(exportData)+";return {Level : Level}})"; 
			
			var file:File = File.desktopDirectory.resolvePath("dataDemo.js");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(js);
			stream.close();
			
			Alert.show("保存成功！");
		}
		
		public function makeNewLevel(name:String):void
		{
			
			levelXML.appendChild(new XML("<level label='"+name+"'></level>"));
			var o:Object = new Object;
			o.levelName = name;
			o.data = new Array;
			displayData.push(o);
		}
		
		public function deleteLevel(name:String):void
		{
			var x = levelXML.level.(@label=="level2");
			return;
			delete levelXML.level.(@label==name)[0];
			for(var l in displayData)
				if(displayData[l].levelName == name)
				{
					delete displayData[l];
				}
		}
		public function parseLevelXML(data:Object):XML
		{
			var levels:XML = <Root></Root>
			for each(var item in data)
				levels.appendChild(new XML("<level label='"+item.levelName+"'></level>"));
			return levels;
		}
		
		public function updateLevelData(name:String, data:Array, endTime:int):void
		{
			var obj:Object = getLevelData(name);
			if(obj)
			{
				obj.endTime = endTime;
				obj.data = data;
			}
		}
		
		public function getLevelData(levelName:String):Object
		{
			for each(var item in displayData)
				if(item.levelName == levelName)
					return item;
			return null;
		}
		
		
		private function onLoadMatsData(data:Object):void
		{
			
			for(var item in data)
			{
				matsData[item] = new Object;
				matsData[item].sourcePath = data[item].face+".png";
			}
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}