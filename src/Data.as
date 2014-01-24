package
{
	import com.as3xls.xls.ExcelFile;
	import com.as3xls.xls.Sheet;
	import com.hurlant.crypto.symmetric.NullPad;
	
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
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import editEntity.TriggerSprite;
	
	import excel.ExcelReader;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	
	public class Data extends EventDispatcher
	{
		public var conf:Object = null;
		public var matsData:Object = null;
		public var enemyData:Object = null;
		public var enemyEditData:Object = null;
		public var behaviorData:Object = null;
		public var displayData:Array = null;
		public var levelXML:XML = null;
		public var enemySkinDic:Dictionary;
		public var currSelectedLevel:int = 0;
		
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
			autoSaveTimer = new Timer(600000, 1);
			autoSaveTimer.addEventListener(TimerEvent.TIMER, onAutoSave);
			autoSaveTimer.start();
		}
		
		public function init():void
		{
			var file:File = File.desktopDirectory.resolvePath("editor/data.json");
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
				
				if(!conf.hasOwnProperty("speed"))
				{
					conf = new Object;
					conf.speed = 32;
				}
			}
			else
			{
				conf = new Object;
				conf.speed = 32;
			}
			
			EventManager.getInstance().addEventListener(EventType.EXCEL_DATA_CHANGE, onDataComplete);
			ExcelReader.getInstance().initWithNativePath(File.desktopDirectory.resolvePath("editor/levelData.xlsx").nativePath);
			
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
			
			var f:File = File.desktopDirectory.resolvePath("editor/skins");
			if(!f.exists)
			{
				Alert.show("editor/skins文件夹不存在！");
				return;
			}
			for(var item in enemyData)
			{
				var bytes:ByteArray = new ByteArray;
				var file:File = File.desktopDirectory.resolvePath("editor/skins/"+enemyData[item].face+".png");
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				stream.readBytes(bytes);
				stream.close();
				
				var loader:Loader = new Loader;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadSkin);
				loader.loadBytes(bytes);
				loaderDic[loader] = item;
			}
			
				
			var file:File = File.desktopDirectory.resolvePath("editor/enemyMoveData.json");
			enemyEditData = null;
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				enemyEditData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			
			if(!enemyEditData)
			{
				enemyEditData = new Object;
				for(var item in enemyData)
				{
					enemyEditData[item] = new Object;
				}
			}
			
			file = File.desktopDirectory.resolvePath("editor/behavior.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				behaviorData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
				behaviorData = new Object;
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
			var file:File = File.desktopDirectory.resolvePath("editor/data.json");
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
			var file:File = File.desktopDirectory.resolvePath("editor/enemyMoveData.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(enemyEditData));
			stream.close();
		}
		
		public function saveBehaviorData():void
		{
			var file:File = File.desktopDirectory.resolvePath("editor/behavior.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(behaviorData));
			stream.close();
			Alert.show("保存成功！");
		}
		
		public function exportJS():void
		{
			for(var type in enemyEditData)
			{
				if(!enemyData.hasOwnProperty(type))
				{
					delete enemyEditData[type];
					break;
				}
				
				if(enemyEditData[type].hasOwnProperty("move_type"))
				{
					enemyData[type]["move_type"] = enemyEditData[type]["move_type"];
					enemyData[type]["move_args"] = enemyEditData[type]["move_args"];
				}
				
				if(enemyEditData[type].hasOwnProperty("attack_type"))
				{
					enemyData[type]["attack_type"] = enemyEditData[type]["attack_type"];
					enemyData[type]["attack_args"] = enemyEditData[type]["attack_args"];
				}
				
				if(enemyEditData[type].hasOwnProperty("type"))
					enemyData[type]["type"] = enemyEditData[type]["type"];
				else
					enemyData[type]["type"] = "enemy";
			}	
			
			var source:Array = displayData[currSelectedLevel].data;
			/*var positions:Array = new Array;
			for each(var item:Object in source)
			{
				var data:Object = new Object;
				data.type = item.type;
				data.x = item.x;
				data.y = item.y;
				data.id = item.id;
				if(item.hasOwnProperty("triggerId"))
					data.triggerId = item.triggerId;
				if(item.type == TriggerSprite.TRIGGER_TYPE)
				{
					data.width = item.width;
					data.height = item.height;
					data.objs = item.objs;
				}
				if(item.hasOwnProperty("triggerTime"))
					data.triggerTime= item.triggerTime;
				else
					data.triggerTime = item.y;
				
				positions.push(data);
			}
			var exportData:Object = new Object();
			exportData["pos"] = positions;
			if (enemyData) {
				exportData["defs"] = enemyData;
			}
			var map:Object = new Object;
			map.speed = conf.speed;
			exportData["map"] = map;*/
			
			var exportData:Object = new Object;
			exportData.actor = new Object;
			exportData.trap = new Object;
			exportData.objects = new Array;
			exportData.trigger = new Array;
			for(var name in enemyData)
			{
				var data:Object = enemyData[name];
				data.actions = new Array;
				if(data.move_type != 0)
				{
					var action:Object = data.move_args;
					action.type = data.move_type;
					data.actions.push(action);
					
					delete data.move_args;
				}
				if(data.attack_type != "")
				{
					var action2:Object = data.attack_args;
					action2.type = data.attack_type == "M" ? "MeleeAttack" : "RangedAttack";
					data.actions.push(action2);
				}
				delete data.move_type;
				delete data.attack_type;
				delete data.attack_args;
				exportData.actor[name] = data;
			}
			
			for each(var item:Object in source)
			{
				if(item.type == "AreaTrigger")
				{
					var triData:Object = new Object;
					var condData = new Object;
					condData.type = "Area";
					condData.area = new Array;
					condData.area.push(item.x);
					condData.area.push(item.y);
					condData.area.push(item.width);
					condData.area.push(item.height);
					triData.cond = condData;
					
					var resultData:Object = new Object;
					resultData.type = "Object";
					resultData.objs = item.objs;
					triData.result = resultData;
					exportData.trigger.push(triData);
				}
				else
				{
					var objData:Object = new Object;
					objData.id = item.id;
					objData.name = item.type;
					objData.coord = new Array(item.x, item.y);
					exportData.objects.push(objData);
					
					if(!item.hasOwnProperty("triggerId"))
					{
						triData = new Object;
						condData = new Object;
						condData.type = "Time";
						condData.time = item.y;
						triData.cond = condData;
						
						resultData = new Object;
						resultData.type = "Object";
						resultData.objs = new Array(item.id);
						triData.result = resultData;
						exportData.trigger.push(triData);
					}
				}
				
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