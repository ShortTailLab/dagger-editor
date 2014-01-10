package
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import excel.ExcelReader;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	
	public class Data extends EventDispatcher
	{
		public var conf:Object = null;
		public var matsData:Object = null;
		public var enemyData:Object = null;
		public var enemyMoveData:Object = null;
		public var displayData:Array = null;
		public var levelXML:XML = null;
		public var enemySkinDic:Dictionary;
		
		private var autoSaveTimer:Timer;
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
			autoSaveTimer = new Timer(60000, 1);
			autoSaveTimer.addEventListener(TimerEvent.TIMER, onAutoSave);
			autoSaveTimer.start();
		}
		
		public function init():void
		{
			var file:File = File.desktopDirectory.resolvePath("data.json");
			var stream:FileStream;
			if(file.exists)
			{
				stream = new FileStream;
				stream.open(file, FileMode.READ);
				displayData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable)) as Array;
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
			
			file = File.desktopDirectory.resolvePath("editor/conf.json");
			if(file.exists)
			{
				stream = new FileStream;
				stream.open(file, FileMode.READ);
				conf = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
			{
				conf = new Object;
				conf.timeLineUnit = 100;
			}
			
			ExcelReader.getInstance().initWithRelativePath("Resource/levelData.xlsx", onDataComplete);
			EventManager.getInstance().addEventListener(EventType.EXCEL_DATA_CHANGE, onDataComplete);
		}
		
		private var loaderDic:Dictionary;
		private var skinLength:int = 0;
		private function onDataComplete(e:GameEvent = null):void
		{
			// do sth.
			enemyData = ExcelReader.getInstance().enemyData;
			loaderDic = new Dictionary;
			enemySkinDic = new Dictionary;
			skinLength = 0;
			loadCount = 0;
			for(var i in enemyData)
				skinLength++;
			
			for(var item in enemyData)
			{
				var path:String = enemyData[item].face+".png";
				var loader = new Loader;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadSkin);
				loader.load(new URLRequest("Resource/"+path));
				loaderDic[loader] = item;
			}
			
				
			var file:File = File.desktopDirectory.resolvePath("enemyMoveData.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				enemyMoveData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
			{
				enemyMoveData = new Object;
				for(var item in enemyData)
					if(enemyData[item].hasOwnProperty("move_type"))
					{
						enemyMoveData[item] = new Object;
						enemyMoveData[item]["move_type"] = enemyData[item]["move_type"]; 
						enemyMoveData[item]["move"] = new Object;
						for(var moveItem in enemyData[item]["move"])
						{
							enemyMoveData[item]["move"][moveItem] = enemyData[item]["move"][moveItem];
						}
					}
			}
		}
		private var loadCount:int = 0;
		private function onLoadSkin(e:Event):void
		{
			var loader:Loader = (e.target as LoaderInfo).loader;
			enemySkinDic[loaderDic[loader]] = Bitmap(loader.content).bitmapData; 
			if(++loadCount >= skinLength)
			{
				this.dispatchEvent(new Event(Event.COMPLETE));
				EventManager.getInstance().dispatchEvent(new GameEvent(EventType.ENEMY_DATA_UPDATE));
			}
		}
		
		public function saveLocal():void
		{
			var file:File = File.desktopDirectory.resolvePath("data.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(displayData));
			stream.close();
			
			file = File.desktopDirectory.resolvePath("editor/conf.json");
			stream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(conf));
			stream.close();
			
			saveEnemyData();
			autoSaveTimer.reset();
			autoSaveTimer.start();
		}
		
		public function saveEnemyData():void
		{
			var file:File = File.desktopDirectory.resolvePath("enemyMoveData.json");
			var stream:FileStream = new FileStream;
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
			
			var js:String = "function MAKE_LEVEL(){ var level = " +
				"" + JSON.stringify(exportData, null, "\t") + "; return level; }"; 
			
			var file:File = File.desktopDirectory.resolvePath("editor/Resources/level/demo.js");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(js);
			stream.close();
			
			Alert.show("保存成功！");
		}
		
		private function onAutoSave(e:TimerEvent):void
		{
			saveLocal();
		}
		
		public function makeNewLevel(name:String):void
		{
			
			levelXML.appendChild(new XML("<level label='"+name+"'></level>"));
			var o:Object = new Object;
			o.levelName = name;
			o.data = new Array;
			displayData.push(o);
		}
		
		public function deleteLevel(index:int):void
		{
			var name:String = levelXML.level[index].@label;
			delete levelXML.level[index];
			for(var l in displayData)
				if(displayData[l].levelName == name)
				{
					displayData.splice(l, 1);
					saveLocal();
					break;
				}
		}
		public function renameLevel(index:int, name:String):void
		{
			levelXML.level[index].@label = name;
			displayData[index].levelName = name
			saveLocal();
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