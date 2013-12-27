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
			
			var loader:URLLoader = new URLLoader;
			loader.addEventListener(Event.COMPLETE, onLoadMatsData);
			loader.load(new URLRequest("Resource/enemyData.xml"));
			
			_excelReader = new ExcelReader();
			_excelReader.init(
				function ():void {
					// do sth.
				}
			);
		}
		
		public function exportJS():void
		{
			/*var xlsBytes:ByteArray = new ByteArray;
			var file:File = File.desktopDirectory.resolvePath("data.xlsx");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.READ);
			stream.readBytes(xlsBytes);
			stream.close();
			
			var excel:ExcelFile =new ExcelFile;
			excel.loadFromByteArray(xlsBytes);
			var sheet:Sheet = excel.sheets[3];*/
			
			var source:Array = displayData[0].data;
			var positions:Array = new Array;
			for each(var item:Object in source)
			{
				var data:Object = new Object;
				data.type = item.type;
				data.x = item.x*2;
				data.y = -item.y/20;
				positions.push(data);
			}
			var exportData:Object = new Object();
			exportData["pos"] = positions;
			if (_excelReader.enemyData) {
				exportData["defs"] = _excelReader.enemyData;
			}
			
			var js:String = "module('level_data', function(){ var Level = {};Level.demo = " +
				""+JSON.stringify(exportData)+";return {Level : Level}})"; 
			
			var file:File = File.desktopDirectory.resolvePath("dataDemo.js");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(js);
			stream.close();
			
			Alert.show("导出成功！");
		}
		
		public function onLoadXLS():void
		{
			var source:Array = displayData[0].data;
			var exportData:Array = new Array;
			for each(var item:Object in source)
			{
				var data:Object = new Object;
				data.type = item.type;
				data.x = item.x*2;
				data.y = -item.y/20;
				exportData.push(data);
			}

			var js:String = "module('level_data', function(){ var Level = {};Level.demo = {" +
				""+JSON.stringify(exportData)+"};return {Level : Level}})"; 
			
			var file:File = File.desktopDirectory.resolvePath("dataDemo.js");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(js);
			stream.close();
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
		
		public function export():void
		{
			var file:File = File.desktopDirectory.resolvePath("data.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(displayData));
			stream.close();
			Alert.show("保存成功！");
		}
		
		private function onLoadMatsData(e:Event):void
		{
			var matsXML:XML = XML((e.target as URLLoader).data);
			
			for each(var item:XML in matsXML.item)
			{
				matsData[item.type] = new Object;
				matsData[item.type].sourcePath = item.path;
			}
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
	}
}