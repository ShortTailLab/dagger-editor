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
		public var enemy_trigger:Object = null;
		
		// instances of enemy and map configs for every level
		public var levels:Array = null;
		public var level_xml:XML = null;
		
		// static image of enemies
		public var skins:Dictionary; 
		
		// behavior 
		public var bh_lib:Object = null;
		public var bh_node:Object = null;
		public var bh_xml:XML = null;
		
		// misc
		public var dynamic_args:Object = null;
		
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
			//		src: "http://svn.stl.com/策划文档/屌丝RPG/profiles.xlsx",
			//		type : URLLoaderDataFormat.BINARY
			// },
			//
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/bt_node_format.json",
				suffix: "bt_node_format.json"
				//type: URLLoaderDataFormat.TEXT
			},
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/dynamic_args.json",
				suffix: "dynamic_args.json"
				//type: URLLoaderDataFormat.TEXT
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
					trace("sync "+item.suffix+" done");
					Utils.write(e.target.data, "editor/data/"+item.suffix);
						
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
			this.levels = this.loadJson("editor/saved/levels.json") as Array;

			if( !this.levels ) 
			{
				this.levels = new Array;
				this.levels.push({
					levelName 	: "level-1",
					endTime 	: 0,
					data 		: new Array
				});
			}  
			this.currSelectedLevel = this.levels.length-1;
			this.level_xml = this.parseLevelXML(this.levels);
			
			this.bh_lib = this.loadJson("editor/saved/bh_lib.json", false);
			if( !this.bh_lib )  this.bh_lib = new Object;
			this.bh_xml = this.parseBehaviorXML(this.bh_lib);
			
			this.conf = this.loadJson("editor/saved/conf.json", false);
			if( !this.conf ) this.conf = { speed: 32};
			//this record the behaviors' name of each enemy
			this.enemy_bh = this.loadJson("editor/saved/enemy_bh.json", false) || {};
			this.enemy_trigger = this.loadJson("editor/saved/enemy_trigger.json", false) || {};

			// load configs 
			this.dynamic_args = this.loadJson("editor/data/dynamic_args.json");
			this.bh_node = this.loadJson("editor/data/bt_node_format.json");
			
			// async loading
			// ---------------------------------------------------------------
			// exceptional case, bad design, refactor this.
			var self:* = this; this.skins = new Dictionary;
			var onexceldone:Function = function(e:Event):void
			{	
				// enemy_profile
				self.enemy_profile = ExcelReader.getInstance().enemyData;
				var length:Number = 0, countor:Number = 0;
				var alldone:Function = function(key:String):Function
				{
					return function(e:Event):void
					{
						var face:String = self.enemy_profile[key].face;
						var loader:Loader = (e.target as LoaderInfo).loader; 
						self.skins[face] = Bitmap(loader.content).bitmapData;
						if( ++countor >= length ) self.start();
					}
				}
					
				for(var key:String in self.enemy_profile)
				{
					var face:String = self.enemy_profile[key].face;
					if( self.skins.hasOwnProperty(face) ) continue;
					
					length ++;
					self.skins[face] = "icu";
					
					var bytes:ByteArray = new ByteArray;
					var filepath:String = "editor/skins/"+self.enemy_profile[key].face+".png";
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
			var file:File = File.desktopDirectory.resolvePath("editor/data/profiles.xlsx");
			if(file.exists)
			{
				EventManager.getInstance().addEventListener(EventType.EXCEL_DATA_CHANGE, onexceldone);
				ExcelReader.getInstance().initWithNativePath(file.nativePath);
			}
			else Alert.show("profiles.xlsx 丢失！");
			// ---------------------------------------------------------------
		}

		private function start():void
		{
			// clean up
			{
				for(var orgItem:* in this.enemy_bh)
				{
					//clear the items which enemy id is invalid
					if(!this.enemy_profile.hasOwnProperty(orgItem))
						delete this.enemy_bh[orgItem];
					//clear the unexist behaviors of each item.
					var behaviorsOfEnemy:Array = this.enemy_bh[orgItem] as Array;
					if( !behaviorsOfEnemy ) continue;
					for(var j:int = 0; j < behaviorsOfEnemy.length; j++)
						if(!this.bh_lib.hasOwnProperty(behaviorsOfEnemy[j]))
							behaviorsOfEnemy.splice(j--, 1);
				}
				for(var bName in this.enemy_profile)
					if(!enemy_bh.hasOwnProperty(bName))
						enemy_bh[bName] = new Array;
			}
			
			// let's rock 'n' roll
			this.dispatchEvent( new Event(Event.COMPLETE) );
			EventManager.getInstance().dispatchEvent(new GameEvent(EventType.ENEMY_DATA_UPDATE));
		}
		
		// -------------------------------------------------------------
		// persistence
		public function saveLocal(e:TimerEvent=null):Boolean
		{
			Utils.copyDirectoryTo("editor/saved/","editor/backup/");
			
			Utils.writeObjectToJsonFile(this.levels, "editor/saved/levels.json");
			Utils.writeObjectToJsonFile(this.conf, "editor/saved/conf.json");
			Utils.writeObjectToJsonFile(this.enemy_trigger, "editor/saved/enemy_trigger.json");
			Utils.writeObjectToJsonFile(this.enemy_bh, "editor/saved/enemy_bh.json");
			Utils.writeObjectToJsonFile(this.bh_lib, "editor/saved/bh_lib.json");
			
			autoSaveTimer.reset(); autoSaveTimer.start();
			return true;
		}
		
		public function exportJS():Boolean
		{
			if( this.currSelectedLevel < 0 ) {
				Alert.show("无被选中的关卡");
				return false;
			}
			
			var export:Object = new Object;
			var source:Array = this.levels[this.currSelectedLevel].data;
			
			// confs
			export.map = { speed : this.conf.speed };
			
			// parse instances 
			export.objects = new Object, export.trigger = new Array;
			var actors:Object = {}, traps:Object = {};
			for each( var item:* in source ) 
			{
				if( item.type == "AreaTrigger" ) {
					export.trigger.push({
						cond : {
							type: "Area",
							area: "@@cc.rect("+item.x+","+item.y+","+item.width+","+item.height+")@@"
						},
						result : {
							type: "Object", objs : item.objs
						}
					});
					continue;
				}

				var data:Object = this.enemy_profile[item.type];
				if( data.type == "bullet" ) {
					Alert.show("子弹类型不可被放置在地图中"); 
					return false;
				}
				if( data.type == "actor" ) actors[item.type] = data;
				else traps[item.type] = data;
				
				var t:Number = item.triggerTime || item.y;
				export.objects[item.id] = {
					name : item.type, coord:"@@cc.p("+item.x+","+item.y+")@@",
					time : t
				};
			}
			
			export.actor = new Object; 
			var bhs:Object = {};
			for( var key:String in actors )
			{
				if( !this.enemy_bh.hasOwnProperty(key) || this.enemy_bh[key].length == 0 ) {
					Alert.show("敌人"+key+"未被设置行为");
					return false;
				}
				
				export.actor[key] = Utils.deepCopy(actors[key]);	
				export.actor[key].behaviors = this.enemy_bh[key];
				export.actor[key].triggers = this.enemy_trigger[key] || [];
				this.enemy_bh[key].forEach(function(item:*, ...args):void {
					bhs[item] = true;
				}, null);
			}
			
			export.behavior = new Object;
			for( var key:String in bhs )
			{
				if( !this.bh_lib.hasOwnProperty(key) ) {
					Alert.show("试图导出不存在的行为"+key);
					return false;
				}
				var raw:String = Utils.genBTreeJS(this.bh_lib[key]);
				export.behavior[key] = String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
					""+raw+";}@@");
			} 
			
			export.trap = new Object;
			for(  var key:* in traps )
				export.trap[key] = Utils.deepCopy(traps[key]);
			
			// export bullet
			export.bullet = new Object;
			for( var key:* in this.enemy_profile ) {
				if(this.enemy_profile[key].type == "bullet")
				{
					for( var bh:String in export.behavior )
					{
						if( export.behavior[bh].search(key) != -1)
						{
							export.bullet[key] = this.enemy_profile[key];
						}
					}
				}
			}
			
			// undefined
			export.luck = new Object;
			
			var content:String = JSON.stringify(export, null, "\t");
			var wrap:String = "function MAKE_LEVEL(){ var level = " + 
				adjustJS(content) + "; return level; }"; 
			Utils.write(wrap, "editor/export/level/demo.js");
			return true;
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
			this.levels.push({
				levelName : name,
				endTime : 0,
				data : new Array
			});
		}
		
		public function deleteLevel(index:int):void
		{
			var name:String = this.level_xml.level[index].@label;
			delete this.level_xml.level[index];
			for(var l:String in this.levels)
				if(this.levels[l].levelName == name)
				{
					this.levels.splice(l, 1);
					this.saveLocal();
					break;
				}
			
			if(this.levels.length == 0)
			{
				this.levels.push({
					levelName : "Level-1",
					endTime : 0,
					data : new Array
				});
				this.level_xml = parseLevelXML(this.levels);
			}
		}
		
		public function renameLevel(index:int, name:String):void
		{
			this.level_xml.level[index].@label = name;
			this.levels[index].levelName = name
			this.saveLocal();
		}
		public function parseLevelXML(data:Object):XML
		{
			var levels:XML = <Root></Root>;
			for each(var item:* in data)
				levels.appendChild(new XML("<level label='"+item.levelName+"'></level>"));
			return levels;
		}
		
		public function parseBehaviorXML(data:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b:* in data)
				xml.appendChild(new XML("<behavior label='"+b+"'></behavior>"));
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
			if(isChangeEnemyData) this.saveLocal();
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
				if(isChangeEnemyData) this.saveLocal();
				
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
				this.saveLocal();
			}
			else
				trace("set enemy data: enemytype not exist!");
		}
		
		public function updateLevelData(name:String, data:Array, endTime:int):void
		{
			var obj:Object = getLevelData(name);
			
			// merge
			if(obj)
			{
				obj.endTime = endTime;
				obj.data = data;
			}
		}
		
		public function getLevelData(levelName:String):Object
		{
			for each(var item:* in this.levels)
				if(item.levelName == levelName)
					return item;
			return null;
		}
		
		public function setEnemyTrigger(id:String, triggers:Object):void
		{
			this.enemy_trigger[id] = triggers;
		}
	}
}