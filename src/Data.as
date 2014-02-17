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
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	import behaviorEdit.BType;
	import behaviorEdit.BehaviorEvent;
	
	import excel.ExcelReader;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	public class Data extends EventDispatcher
	{
		public var conf:Object = null;
		public var matsData:Object = null;
		public var enemyData:Object = null;
		//public var enemyEditData:Object = null; // unused
		public var enemyBTData:Object = null;
		public var behaviors:Object = null;
		public var displayData:Array = null;
		public var levelXML:XML = null;
		public var behaviorsXML:XML = null;
		public var enemySkinDic:Dictionary;
		public var currSelectedLevel:int = -1;
		public var behaviorBaseNode:Object = null;
		public var dynamicArgs:Object = null;
		public var descOfTriggers:Object = null;
		
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
		
		// entrance of Data
		public function init():void { this.sync(); }
		// ---------------------------------------------------
		// where is the built-in functional package?
		// ---------------------------------------------------
		private const syncTargets:Array = [
			// LAN only, should port this file to oss 
			// { 
			//		src: "http://svn.stl.com/策划文档/屌丝RPG/levelData.xlsx",
			//		type : URLLoaderDataFormat.BINARY
			// },
			//
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/bt_node_format.json",
				suffix: "bt_node_format.json",
				type: URLLoaderDataFormat.TEXT
			},
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/dynamic_args.json",
				suffix: "dynamic_args.json",
				type: URLLoaderDataFormat.TEXT
			}
		];
		// where is the synchronous loader? WTF...
		private function sync():void
		{
			var counter:Number = 0;
			var error:Boolean = false;
			var alldone:Function = function(item:Object):Function
			{
				// [TODO] dispatch handler by item.type
				var handleTEXT:Function = function(e:Event):void
				{
					var file:File = File.desktopDirectory.resolvePath("editor/data/"+item.suffix);
					var stream:FileStream = new FileStream;
					stream.open(file, FileMode.WRITE);
					stream.writeUTFBytes(e.target.data);
					
					if( ++counter >= syncTargets.length && !error )
						this.load();
				}
				return handleTEXT;
			}
			var anyerror:Function = function():void
			{
				error = true;
				Alert.show("[WARN]同步服务器出错，将会使用本地数据…");
				this.load();
			}
			syncTargets.forEach(function(item:Object):void
			{
				var loader:URLLoader = new URLLoader;
				loader.dataFormat = item.type;
				loader.addEventListener(Event.COMPLETE, alldone(item));
				loader.addEventListener(IOErrorEvent.IO_ERROR, anyerror);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, anyerror);
				loader.load( new URLRequest(item.src) );
			}, null);
		}
		// ---------------------------------------------------
		// 
		private function loadJson(filepath:String, warn:Boolean=true):Object
		{
			var ret:Object = Utils.loadJsonFileToObject(filepath);
			if( !ret && warn)
			{
				Alert.show(filepath+"无法被载入内存或无法被解析！");
				return null;
			}
			return ret;
		}
		private function load():void
		{
			// saved informations
			var data:Object = this.loadJson("editor/data.json");
			if( !data )
			{
				this.displayData = new Array;
				this.displayData.push({
					levelName 	: "level-1",
					endTime 	: 0,
					data 		: new Array
				});
			}  
			this.levelXML = this.parseLevelXML(displayData);
			
			this.behaviors = this.loadJson("editor/behaviors.json", false);
			if( !this.behaviors )  this.behaviors = new Object;
			this.behaviorsXML = this.parseBehaviorXML(this.behaviors);
			
			this.conf = this.loadJson("editor/conf.json", false);
			if( !conf ) conf = { speed: 32}
			this.dynamicArgs = this.loadJson("editor/dynamic_args.json");
			this.behaviorBaseNode = this.loadJson("editor/bt_node_format.json");
			//this record the behaviors' name of each enemy
			this.enemyBTData = this.loadJson("editor/enemyBehaviorsData.json");

			
			// async loading
			// ---------------------------------------------------------------
			// exceptional case, bad design, refactor this.
			this.enemySkinDic = new Dictionary;
			var onexceldone:Function = function(e:Event):void
			{
				var length:Number = 0, countor:Number = 0;
				for(var i:* in this.enemyData) length ++;
				
				this.enemyData = ExcelReader.getInstance().enemyData;
				var alldone:Function = function(item:*):Function
				{
					return function(e:Event):void
					{
						var loader:Loader = (e.target as LoaderInfo).loader; 
						this.enemySkinDic[item] = Bitmap(loader.content).bitmapData;
						if( ++countor >= length ) this.start();
					}
				}
				
				for(var item:* in enemyData)
				{
					var bytes:ByteArray = new ByteArray;
					var filepath:String = "editor/skins/"+item.face+".png";
					var file:File = File.desktopDirectory.resolvePath(filepath);
					var stream:FileStream = new FileStream();
					stream.open(file, FileMode.READ);
					stream.readBytes(bytes);
					stream.close();
					
					var loader:Loader = new Loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, alldone(item));
					loader.loadBytes(bytes);
				}
				
			}
			var file:File = File.desktopDirectory.resolvePath("editor/levelData.xlsx");
			if(file.exists)
			{
				EventManager.getInstance().addEventListener(EventType.EXCEL_DATA_CHANGE, onexceldone);
				ExcelReader.getInstance().initWithNativePath(file.nativePath);
			}
			else Alert.show("levelData丢失！");
			// ---------------------------------------------------------------
		}

		private function start():void
		{
			//you can see the struct of enemyBTData here.
			{
				for(var orgItem:* in this.enemyBTData)
				{
					//clear the items which enemy id is invalid
					if(!this.enemyData.hasOwnProperty(orgItem))
						delete this.enemyBTData[orgItem];
					//clear the unexist behaviors of each item.
					var behaviorsOfEnemy:Array = this.enemyBTData[orgItem] as Array;
					for(var j:int = 0; j < behaviorsOfEnemy.length; j++)
						if(!this.behaviors.hasOwnProperty(behaviorsOfEnemy[j]))
							behaviorsOfEnemy.splice(j--, 1);
				}
			}
			
			// let's rock 'n' roll
			this.dispatchEvent(new Event(Event.COMPLETE));
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.ENEMY_DATA_UPDATE));
		}
		
		public function saveLocal():void
		{
			genBackUp("data.json");
			
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
			
			autoSaveTimer.reset();
			autoSaveTimer.start();
		}
		
		public function saveEnemyBehaviorData():void
		{
			
			var file:File = File.desktopDirectory.resolvePath("editor/enemyBehaviorsData.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(enemyBTData));
			stream.close();
		}
		
		public function saveBehaviorData():void
		{
			genBackUp("behaviors.json");
			var file:File = File.desktopDirectory.resolvePath("editor/behaviors.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(behaviors));
			stream.close();
		}
		
		private function genBackUp(path:String):void
		{
			var file:File = File.desktopDirectory.resolvePath("editor/"+path);
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				var backupData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				
				file = File.desktopDirectory.resolvePath("editor/backup/"+path);
				stream = new FileStream;
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(JSON.stringify(backupData));
				stream.close();
			}
			
		}
		
		
		public function exportJS():void
		{
			if(currSelectedLevel < 0)
				return;
			
			var source:Array = displayData[currSelectedLevel].data;
			
			var exportData:Object = new Object;
			
			exportData.actor = new Object;
			exportData.trap = new Object;
			exportData.objects = new Object;
			exportData.trigger = new Array;
			exportData.bullet = new Object;
			exportData.luck = new Object;
			exportData.behavior = new Object;
			
			exportData.map = new Object;
			exportData.map.speed = this.conf.speed;
			
			for(var bName in behaviors)
			{
				var js:String = Utils.genBTreeJS(behaviors[bName]);
				if(js == "")
				{
					Alert.show("导出行为"+bName+"脚本出错，请检查");
					return;
				}
				exportData.behavior[bName]= String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
					""+js+";}@@");
			}
			
			for(var name in enemyData)
			{
				var data:Object = Utils.deepCopy(enemyData[name]);
				var behaviors:Object;
				if(enemyBTData.hasOwnProperty(name))
					behaviors = enemyBTData[name];
				else
					behaviors = new Array;
				
				if(data.type == "bullet")
				{
					exportData.bullet[name] = data;
					delete data.type;
				}
				else if(data.type == "actor")
				{
					exportData.actor[name] = data;
					exportData.actor[name].behaviors = behaviors;
					delete data.type;
				}
				else if(data.type == "RollingStone" || data.type == "Meteorite" || data.type == "Bangalore")
				{
					exportData.trap[name] = data;
					exportData.behaviors = behaviors;
				}
				
			}
			
			for each(var item:Object in source)
			{
				if(item.type == "AreaTrigger")
				{
					var triData:Object = new Object;
					var condData = new Object;
					condData.type = "Area";
					condData.area = "@@cc.rect("+item.x+","+item.y+","+item.width+","+item.height+")@@";
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
					objData.name = item.type;
					objData.coord = "@@cc.p("+item.x+","+item.y+")@@";
					exportData.objects[item.id] = objData;
					
					if(!item.hasOwnProperty("triggerId"))
					{
						triData = new Object;
						condData = new Object;
						condData.type = "Time";
						condData.time = item.hasOwnProperty("triggerTime") ? item.triggerTime : item.y;
						triData.cond = condData;
						
						resultData = new Object;
						resultData.type = "Object";
						resultData.objs = new Array(item.id);
						triData.result = resultData;
						exportData.trigger.push(triData);
					}
				}
				
			}
			
			var content:String = JSON.stringify(exportData, null, "\t");
			content = adjustJS(content);
			
			var js:String = "function MAKE_LEVEL(){ var level = " +
				"" + content + "; return level; }"; 
			
			var file:File = File.desktopDirectory.resolvePath("editor/Resources/level/demo.js");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(js);
			stream.close();
			
			Alert.show("保存成功！");
		}
		
		private function adjustJS(js:String):String
		{
			var reg1:RegExp = /"@@|@@"/g;
			var result:String = "";
			result = js.replace(reg1, "");
			return result;
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
			var levels:XML = <Root></Root>;
			for each(var item in data)
				levels.appendChild(new XML("<level label='"+item.levelName+"'></level>"));
			return levels;
		}
		
		public function parseBehaviorXML(data:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b in data)
				xml.appendChild(new XML("<behavior label='"+b+"'></behavior>"));
			trace("behaviors:"+XMLList(xml.behavior).length());
			return xml;
		}
		
		public function addBehaviors(name:String, data:Object):void
		{
			if(!behaviors.hasOwnProperty(name))
			{
				if(XMLList(behaviorsXML.behavior).length() == 0)
					EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.BT_XML_APPEND));
				
				behaviors[name] = data;
				behaviorsXML.appendChild(new XML("<behavior label='"+name+"'></behavior>"));
				this.saveBehaviorData();
			}
			else
				trace("addBehaviors error: behavior exists!");
		}
		
		public function updateBehavior(name:String, data:Object):void
		{
				behaviors[name] = data;
				this.saveBehaviorData();
		}
		
		public function renameBehavior(prevName:String, currName:String):void
		{
			if(behaviors.hasOwnProperty(currName))
			{
				trace("renamebehavior:currname is invalid!");
				return;
			}
			var isChangeEnemyData:Boolean = false;
			for each(var btData:Array in enemyBTData)
			{
				var i:int = btData.indexOf(prevName);
				if(i >= 0)
				{
					isChangeEnemyData = true;
					btData[i] = currName;
				}
			}
			if(isChangeEnemyData)
				this.saveEnemyBehaviorData();
			behaviors[currName] = behaviors[prevName];
			delete behaviors[prevName];
			behaviorsXML = this.parseBehaviorXML(behaviors);
			this.saveBehaviorData();
		}
		
		public function deleteBehaviors(name:String):void
		{
			
			if(behaviors.hasOwnProperty(name))
			{
				var isChangeEnemyData:Boolean = false;
				for each(var btData:Array in enemyBTData)
				{
					var i:int = btData.indexOf(name);
					if(i >= 0)
					{
						isChangeEnemyData = true;
						btData.splice(i, 1);
					}
				}
				if(isChangeEnemyData)
					this.saveEnemyBehaviorData();
				
				delete behaviors[name];
				behaviorsXML = this.parseBehaviorXML(behaviors);
				this.saveBehaviorData();
			}
		}
		
		public function addEnemyBehavior(enemyType:String, bName:String):void
		{
			if(!enemyBTData.hasOwnProperty(enemyType))
			{
				trace("addenemybehavior error:enemyType not exist!");
				return;
			}
			var bts:Array = enemyBTData[enemyType] as Array;
			if(enemyContainsBehavior(enemyType, bName))
			{
				trace("addenemybehavior error:try to add a behavior that has existed!");
				return;
			}
			bts.push(bName);
		}
		
		public function enemyContainsBehavior(enemyType:String, bName:String):Boolean
		{
			var bts:Array = enemyBTData[enemyType] as Array;
			return bts.indexOf(bName) >= 0;
		}
		
		public function setEnemyBehavior(enemyType:String, bName:String):void
		{
			if(this.enemyBTData.hasOwnProperty(enemyType))
			{
				enemyBTData[enemyType] = new Array;
				if(bName != "")
					enemyBTData[enemyType].push(bName);
				saveEnemyBehaviorData();
			}
			else
				trace("set enemy data: enemytype not exist!");
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

class FunctionObj
{
	private var content:String = ""
	function FunctionObj(_content:String)
	{
		content = _content;	
	}
	
	public function toJSON(k):*
	{
		return content;
	}
}