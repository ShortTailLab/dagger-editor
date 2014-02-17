package
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
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
	import behaviorEdit.BehaviorEvent;
	
	import excel.ExcelReader;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	public class Data extends EventDispatcher
	{
		public var conf:Object = null;
		
		// definition of enemies
		public var enemy_bh:Object = null;
		public var enemy_profile:Object = null;
		
		// instances of enemy and map configs for every level
		public var levels:Array = null;
		public var level_xml:XML = null;
		
		// static image of enemies
		public var skins:Dictionary; 
		
		// behavior 
		public var bh_lib:Object = null;
		public var bh_node:Object = null;
		public var bh_xml:Object = null;
		
		// misc
		public var dynamic_args:Object = null;
		public var desc_of_triggers:Object = null;
		
		// anchors
		public var currSelectedLevel:int = -1;
		private var autoSaveTimer:Timer;
		// -------------------------------------------------
		private static var instance:Data = null;
		public static function getInstance():Data
		{
			if(!instance) instance = new Data;
			return instance;
		}
		// -------------------------------------------------
		
		public function Data(target:IEventDispatcher=null)
		{
			super(target); var self:* = this;
		
			this.autoSaveTimer = new Timer(600000, 1);
			this.autoSaveTimer.addEventListener(
				TimerEvent.TIMER, function():void { self.saveLocal(); }
			);
			this.autoSaveTimer.start();
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
			//trace("sync");
			var self:* = this, counter:Number = 0, error:Boolean = false;
			var alldone:Function = function(item:Object):Function
			{
				// [TODO] dispatch handler by item.type
				var handleTEXT:Function = function(e:Event):void
				{
					//trace("sync "+item.suffix+" done");
					var file:File = File.desktopDirectory.resolvePath("editor/data/"+item.suffix);
					var stream:FileStream = new FileStream;
					stream.open(file, FileMode.WRITE);
					stream.writeUTFBytes(e.target.data);
					
					if( ++counter >= syncTargets.length && !error )
						self.load();
				}
				return handleTEXT;
			}
			var anyerror:Function = function():void
			{
				error = true;
				Alert.show("[WARN]同步服务器出错，将会使用本地数据…");
				this.load();
			}
			syncTargets.forEach(function(item:Object, ...args):void
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
			this.levels = this.loadJson("editor/data/levels.json") as Array;
			if( !this.levels ) 
			{
				this.levels = new Array;
				this.levels.push({
					levelName 	: "level-1",
					endTime 	: 0,
					data 		: new Array
				});
			}  
			this.level_xml = this.parseLevelXML(this.levels);
			
			this.bh_lib = this.loadJson("editor/data/bh_lib.json", false);
			if( !this.bh_lib )  this.bh_lib = new Object;
			this.bh_xml = this.parseBehaviorXML(this.bh_lib);
			
			this.conf = this.loadJson("editor/data/conf.json", false);
			if( !conf ) conf = { speed: 32}
			this.dynamic_args = this.loadJson("editor/data/dynamic_args.json");
			this.bh_node = this.loadJson("editor/data/bt_node_format.json");
			//this record the behaviors' name of each enemy
			this.enemy_bh = this.loadJson("editor/data/enemyBehaviorsData.json");

			
			// async loading
			// ---------------------------------------------------------------
			// exceptional case, bad design, refactor this.=
			var self:* = this;
			this.skins = new Dictionary;
			var onexceldone:Function = function(e:Event):void
			{	
				self.enemyData = ExcelReader.getInstance().enemyData;
				var length:Number = 0, countor:Number = 0;
				var alldone:Function = function(key:String):Function
				{
					return function(e:Event):void
					{
						var face:String = self.enemyData[key].face;
						var loader:Loader = (e.target as LoaderInfo).loader; 
						self.skins[face] = Bitmap(loader.content).bitmapData;
						if( ++countor >= length ) self.start();
					}
				}
					
				for(var key:String in self.enemyData)
				{
					var face:String = self.enemyData[key].face;
					if( self.skins.hasOwnProperty(face) ) continue;
					
					length ++;
					self.skins[face] = "icu";
					
					var bytes:ByteArray = new ByteArray;
					var filepath:String = "editor/skins/"+self.enemyData[key].face+".png";
					var file:File = File.desktopDirectory.resolvePath(filepath);
					
					var stream:FileStream = new FileStream();
					stream.open(file, FileMode.READ);
					stream.readBytes(bytes);
					stream.close();
					
					var loader:Loader = new Loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, alldone(key));
					loader.loadBytes(bytes);
				}
				
			}
			var file:File = File.desktopDirectory.resolvePath("editor/data/levelData.xlsx");
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
				for(var orgItem:* in this.enemy_bh)
				{
					//clear the items which enemy id is invalid
					if(!this.enemy_profile.hasOwnProperty(orgItem))
						delete this.enemy_bh[orgItem];
					//clear the unexist behaviors of each item.
					var behaviorsOfEnemy:Array = this.enemy_bh[orgItem] as Array;
					for(var j:int = 0; j < behaviorsOfEnemy.length; j++)
						if(!this.bh_lib.hasOwnProperty(behaviorsOfEnemy[j]))
							behaviorsOfEnemy.splice(j--, 1);
				}
			}
			
			// let's rock 'n' roll
			this.dispatchEvent( new Event(Event.COMPLETE) );
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.ENEMY_DATA_UPDATE));
		}
		
		// -------------------------------------------------------------
		// persistence
		public function saveLocal(e:TimerEvent=null):void
		{
			Utils.copyDirectoryTo("editor/data/","editor/backup/");
			
			Utils.writeObjectToJsonFile(this.levels, "editor/data/levels.json");
			Utils.writeObjectToJsonFile(this.conf, "editor/data/conf.json");
			Utils.writeObjectToJsonFile(this.enemy_bh, "editor/data/enemyBehaviorsData.json");
			Utils.writeObjectToJsonFile(this.bh_lib, "editor/data/bh_lib.json");
			
			autoSaveTimer.reset(); autoSaveTimer.start();
		}
		
		public function saveEnemyBehaviorData():void
		{
			Utils.writeObjectToJsonFile(this.enemy_bh, "editor/data/enemyBehaviorsData.json");
		}
		
		public function exportJS():void
		{
			if(currSelectedLevel < 0)
				return;
			
			var source:Array = this.levels[currSelectedLevel].data;
			
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
			
			for(var name in enemy_profile)
			{
				var data:Object = Utils.deepCopy(enemy_profile[name]);
				var behaviors:Object;
				if(this.enemy_bh.hasOwnProperty(name))
					behaviors = this.enemy_bh[name];
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
		
		public function makeNewLevel(name:String):void
		{
			this.level_xml.appendChild(new XML("<level label='"+name+"'></level>"));
			var o:Object = new Object;
			o.levelName = name;
			o.data = new Array;
			this.levels.push(o);
		}
		
		public function deleteLevel(index:int):void
		{
			var name:String = this.level_xml.level[index].@label;
			delete this.level_xml.level[index];
			for(var l in this.levels)
				if(this.levels[l].levelName == name)
				{
					this.levels.splice(l, 1);
					saveLocal();
					break;
				}
		}
		
		public function renameLevel(index:int, name:String):void
		{
			this.level_xml.level[index].@label = name;
			this.levels[index].levelName = name
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
			if(!this.bh_lib.hasOwnProperty(name))
			{
				if(XMLList(this.bh_xml.behavior).length() == 0)
					EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.BT_XML_APPEND));
				
				this.bh_lib[name] = data;
				this.bh_xml.appendChild(new XML("<behavior label='"+name+"'></behavior>"));
				this.saveLocal();
			}
			else
				trace("addBehaviors error: behavior exists!");
		}
		
		public function updateBehavior(name:String, data:Object):void
		{
				this.bh_lib[name] = data;
				this.saveLocal();
		}
		
		public function renameBehavior(prevName:String, currName:String):void
		{
			if(this.bh_lib.hasOwnProperty(currName))
			{
				trace("renamebehavior:currname is invalid!");
				return;
			}
			var isChangeEnemyData:Boolean = false;
			for each(var btData:Array in this.enemy_bh)
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
			this.bh_lib[currName] = this.bh_lib[prevName];
			delete this.bh_lib[prevName];
			this.bh_xml = this.parseBehaviorXML(this.bh_lib);
			this.saveLocal();
		}
		
		public function deleteBehaviors(name:String):void
		{
			
			if(this.bh_lib.hasOwnProperty(name))
			{
				var isChangeEnemyData:Boolean = false;
				for each(var btData:Array in this.enemy_bh)
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
				
				delete this.bh_lib[name];
				this.bh_xml = this.parseBehaviorXML(this.bh_lib);
				this.saveLocal();
			}
		}
		
		public function addEnemyBehavior(enemyType:String, bName:String):void
		{
			if(!this.enemy_bh.hasOwnProperty(enemyType))
			{
				trace("addenemybehavior error:enemyType not exist!");
				return;
			}
			var bts:Array = this.enemy_bh[enemyType] as Array;
			if(enemyContainsBehavior(enemyType, bName))
			{
				trace("addenemybehavior error:try to add a behavior that has existed!");
				return;
			}
			bts.push(bName);
		}
		
		public function enemyContainsBehavior(enemyType:String, bName:String):Boolean
		{
			var bts:Array = this.enemy_bh[enemyType] as Array;
			return bts.indexOf(bName) >= 0;
		}
		
		public function setEnemyBehavior(enemyType:String, bName:String):void
		{
			if(this.enemy_bh.hasOwnProperty(enemyType))
			{
				this.enemy_bh[enemyType] = new Array;
				if(bName != "")
					this.enemy_bh[enemyType].push(bName);
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
			for each(var item in this.levels)
				if(item.levelName == levelName)
					return item;
			return null;
		}
	}
}