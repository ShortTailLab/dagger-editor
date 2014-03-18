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
	
	import mx.controls.Alert;
	
	public class Data extends EventDispatcher
	{
		////// entrance
		private static var gDataInstance:Data = null;
		public static function getInstance():Data
		{
			if(!gDataInstance) gDataInstance = new Data;
			return gDataInstance;
		}
		public function Data(target:IEventDispatcher=null) { super(target); }
		
		///////////////////////////////////////////////////////////////////////
		////// editor configs 
		// projectPath 	-> root directroy of data
		// speed 		-> speed & scale factor of map view
		private var mEditorConfigs:Object = null;
		private var mProjectRoot:File = null;
		// --------------------------------------------------------------------------
		public function init():void {
			var config:File = File.applicationStorageDirectory.resolvePath("conf.json");
			this.mEditorConfigs = this.loadJson(config, false);
			
			if( !this.mEditorConfigs ) this.mEditorConfigs = { speed: 32 };
			if( !this.mEditorConfigs.projectPath ) {
				var self:* = this;
				this.setProjectPath( function(file:File)
				{
					self.mProjectRoot = file;
				} );
			}else 
				this.mProjectRoot = new File( this.mEditorConfigs.projectPath );
		}
		
		public function get conf():Object { return mEditorConfigs; }
		public function setEditorConfig(key:String, val:Object ):void
		{
			this.mEditorConfigs[key] = val;
			Utils.WriteObjectToJSON( // persistence
				File.applicationStorageDirectory.resolvePath("conf.json"),
				this.mEditorConfigs
			);
		}
		private function setProjectPath(onComplete:Function):void
		{
			var browser:File = new File();
			browser.browseForDirectory("请选择工程文件夹：");
			browser.addEventListener(Event.SELECT, function (e:Event):void {
				
				var file:File = e.target as File;
				Data.getInstance().setEditorConfig("projectPath", file.nativePath);
				
				onComplete( file );
			});
		}
		private function getFileByRelativePath(sub:String):File
		{
			return this.mProjectRoot.resolvePath( sub );
		}
		
		///////////////////////////////////////////////////////////////////////
		////// data definitions from client
		private var mDynamicArgs:Object 		= {};
		private var mBehaviorNode:Object 		= {};
		private const kSYNC_TARGETS:Array = [
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/bt_node_format.json",
				suffix: "bt_node_format.json"
			},
			{
				src: "http://oss.aliyuncs.com/dagger-static/editor-configs/dynamic_args.json",
				suffix: "dynamic_args.json"
			}
		];
		
		// --------------------------------------------------------------------------
		public function get dynamicArgs():Object { return this.mDynamicArgs; }
		public function get behaviorNodes():Object { return this.mBehaviorNode; }
		
		private function syncClient(onComplete:Function):void
		{
			// download all the configs of client from oss
			var self:* = this, counter:Number = 0, error:Boolean = false;
			var alldone:Function = function(item:Object):Function
			{
				var handleTEXT:Function = function(e:Event):void
				{
					MapEditor.getInstance().addLog("下载"+item.suffix+"成功");
					Utils.write(e.target.data, self.fullpath("editor/data/"+item.suffix));
					
					if( ++counter >= kSYNC_TARGETS.length && !error )
						onComplete("【同步成功】");
				}
				return handleTEXT;
			}
			var anyerror:Function = function():void
			{
				error = true;
				MapEditor.getInstance().addLog("下载失败");
				onComplete("[WARN]同步服务器出错，将会使用本地数据…");
			}
			
			kSYNC_TARGETS.forEach(function(item:Object, ...args):void
			{
				var loader:URLLoader = new URLLoader;
				loader.dataFormat = item.type;
				loader.addEventListener(Event.COMPLETE, alldone(item));
				loader.addEventListener(IOErrorEvent.IO_ERROR, anyerror);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, anyerror);
				loader.load( new URLRequest(item.src) );
				MapEditor.getInstance().addLog("正在下载"+item.suffix+"..");
			}, null);
		}
		
		///////////////////////////////////////////////////////////////////////
		////// second-hand data of editor
		private var mEnemySkins:Dictionary 		= null;
		private var mEnemyProfilesTalbe:Object 	= null;
		
		private var mLevelId2Enemies:Object 	= null;
		
		private var mLevelXML:XML 				= null; 
		//private var mBehaviorXML:XML 			= null;
		
		private function updateEditorData(onComplete:Function):void
		{
			this.mEnemyProfilesTalbe = DataParser.genMonstersTable( this.mLevelProfiles );
			this.mLevelId2Enemies    = DataParser.genLevel2MonsterTable( this.mLevelProfiles );
			
			this.mLevelXML 			 = DataParser.genLevelXML( this.mLevelProfiles );
			//this.mBehaviorXML 		 = Data.par
			
			// load skins async
			this.mEnemySkins 	     = new Dictionary();
			
			var length:Number = 0, countor:Number = 0; 
			var alldone:Function = function(face:String):Function
			{
				var self:Object = this;
				return function(e:Event):void
				{
					var loader:Loader = (e.target as LoaderInfo).loader; 
					self.skins[face] = Bitmap(loader.content).bitmapData;
					MapEditor.getInstance().addLog("加载"+face+"成功");
					if( ++countor >= length ) {
						MapEditor.getInstance().addLog("全部skin加载完成");
						onComplete();
					}
				}
			}
			
			for each(var item:Object in this.mEnemyProfilesTalbe)
			{
				var face:String = item.face;
				if( this.mEnemySkins.hasOwnProperty(face) ) continue;
				this.mEnemySkins[face] = "icu";
				
				var bytes:ByteArray = new ByteArray;
				var file:File = this.getFileByRelativePath("skins/"+face+".png");
				if( !file.exists ) continue;
				
				length ++;
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				stream.readBytes(bytes);
				stream.close();
				
				var loader:Loader = new Loader;
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, alldone(face));
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void{
					MapEditor.getInstance().addLog("加载"+face+"失败");
				});
				loader.loadBytes(bytes);
				MapEditor.getInstance().addLog("加载"+face+"从"+file.nativePath+"..");
			}	
			
			if( length == 0 ) onComplete();
		}
		
		private function validityCheckAndCleanUp():String
		{
			var result:String = "";
			// [TODO] add args checking for behaviors
			
			//clear the unexist behaviors of each item.
			for(var orgItem:* in this.mEnemyBehaviorsTable)
			{
				var behaviorsOfEnemy:Array = this.mEnemyBehaviorsTable[orgItem] as Array;
				if( !behaviorsOfEnemy ) continue;
				for(var j:int = 0; j < behaviorsOfEnemy.length; j++)
					if(!this.mBehaviorSet.hasOwnProperty(behaviorsOfEnemy[j]))
					{
						result += "【删除】行为"+behaviorsOfEnemy[j]+"不存在\n";
						behaviorsOfEnemy.splice(j--, 1);
					}
			}
			
			// clear the undefined enemies of level
			for( var lid:* in this.mLevelProfiles )
			{
				var level:Object = this.mLevelProfiles[lid];
				var table:Object = this.mLevelId2Enemies[lid];
				if( !level || !table ) continue;
				
				for( var x:int = level.data.length-1; x >= 0; x --)
				{
					var monster:Object = level.data[x];
					if( !(monster.type in table) && monster.type != "AreaTrigger" )
					{
						result += "【删除】敌人类型"+monster.type+"未被关卡定义\n";
						level.data.splice( x, 1 );
					}
				}
			}
			
			if( result == "" ) return null;
			return result;
		}
		
		///////////////////////////////////////////////////////////////////////
		////// level data
		// the validity of data below is responsible to upper class
		private var mLevelProfiles:Object 		= null;
		private var mLevelInstancesTable:Object = null;
		
		private var mEnemyBehaviorsTable:Object = null;
		private var mEnemyTriggersTable:Object 	= null;
		
		private var mBehaviorSet:Object 		= null;
		
		// --------------------------------------------------------------------------
		public function getLevelDataById( lid:String ):Object
		{
			return this.mLevelInstancesTable[lid];
		}
		
		public function updateLevelDataById( lid:String, inst:Object ):void
		{
			this.mLevelInstancesTable[lid] = inst;
			Utils.WriteObjectToJSON( // persistence
				this.getFileByRelativePath( "saved/levels.json" ),
				this.mLevelInstancesTable
			);
		}
		
		public function getEnemyTriggersById( eid:String ):Object
		{
			return this.mEnemyTriggersTable[eid];
		}
		
		public function updateEnemyTriggersById( eid:String, triggers:Object ):void
		{
			this.mEnemyTriggersTable[eid] = triggers;
			Utils.WriteObjectToJSON( // persistence
				this.getFileByRelativePath( "saved/enemy_trigger.json" ),
				this.mEnemyTriggersTable
			);
		}
		
		public function getEnemyBehaviorsById( eid:String ):Object
		{
			return this.mEnemyBehaviorsTable[eid];
		}
		
		public function getBehaviorById( bid:String ):Object
		{
			return this.mBehaviorSet[bid];
		}
		public function updateBehaviorSetById( bid:String, data:Object ):void
		{
			this.mBehaviorSet[bid] = data;
			Utils.WriteObjectToJSON( // persistence
				this.getFileByRelativePath( "saved/bh_lib.json" ),
				this.mEnemyTriggersTable
			);
		}
		
		private function parseLocalData()
		{
			this.mLevelProfiles = this.loadJson(
				this.mProjectRoot.resolvePath("saved/profiles.json"), false
			) as Object || {};
			
			this.mLevelInstancesTable = this.loadJson( 
				this.mProjectRoot.resolvePath("saved/levels.json"), false 
			) as Object || {};
			
			this.mEnemyBehaviorsTable = this.loadJson(
				this.mProjectRoot.resolvePath("saved/enemy_bh.json"), false
			) as Object || {};
			
			this.mEnemyTriggersTable = this.loadJson(
				this.mProjectRoot.resolvePath("saved/enemy_trigger.json"), false
			) as Object || {};
			
			this.mBehaviorSet = this.loadJson(
				this.mProjectRoot.resolvePath("saved/bh_lib.json"), false
			) as Object || {};
		}
		
		
		// -------------------------------------------------------------
		// persistence
		public function saveLocal(e:TimerEvent=null):Boolean
		{
			Utils.copyDirectoryTo("editor/saved/","editor/backup/");
//			
//			Utils.writeObjectToJsonFile(
//				this.levels, this.fullpath("editor/saved/levels.json")
//			);
//			Utils.writeObjectToJsonFile(
//				this.enemy_trigger, this.fullpath("editor/saved/enemy_trigger.json")
//			);
//			Utils.writeObjectToJsonFile(
//				this.enemy_bh, this.fullpath("editor/saved/enemy_bh.json")
//			);
//			Utils.writeObjectToJsonFile(
//				this.bh_lib, this.fullpath("editor/saved/bh_lib.json")
//			);
//			Utils.writeObjectToJsonFile(
//				this.mChapter, this.fullpath("editor/saved/chapter.json")
//			);
			
			return true;
		}
		
		
		public function exportJS():String
		{
			var msg:String = "", skips:String = "";
			
//			for each( var lid:String in this.level_list )
//			{
//				if( lid in this.levels )
//				{
//					var r:String = this.exportLevelJS(lid, lid);
//					if( r ) msg += ("["+lid+"]"+r+"\n"); 
//				}
//				//else
//				//	skips += lid+",";
//			}
//			
//			if( this.currSelectedLevel != "" )
//			{	
//				var rr:String = this.exportLevelJS(this.currSelectedLevel, "demo");
//				if( rr )  msg += ("[demo]"+rr+"\n"); 
//			}
//			
//			if( msg == "" ) msg ="【保存成功】";
				
			//return msg+"\n跳过了关卡"+skips.slice(0, -2); why should i care about this?
			return msg;
		}
		
		private function exportLevelJS(lid:String, suffix:String):String
		{	
//			if( !(lid in this.levels) ) return "【失败】无相关地图数据存在";
//				
//			var export:Object = new Object;
//			var source:Array = this.levels[lid].data;
//			
//			// confs
//			export.map = { speed : this.mEditorConfigs.speed };
//			
//			// parse instances 
//			export.objects = new Object, export.trigger = new Array;
//			var actors:Object = {}, traps:Object = {};
//			for each( var item:* in source ) 
//			{
//				if( item.type == "AreaTrigger" ) {
//					export.trigger.push({
//						cond : {
//							type: "Area",
//							area: "@@cc.rect("+item.x+","+item.y+","+item.width+","+item.height+")@@"
//						},
//						result : {
//							type: "Object", objs : item.objs
//						}
//					});
//					continue;
//				}
//
//				var data:Object = this.enemy_profile[item.type];
//				if( data.monster_type == "Bullet" ) {
//					return "【失败】子弹类型不可被放置在地图中"; 
//				}
//				if( data.monster_type == "Monster" ) actors[item.type] = data;
//				else traps[item.type] = data;
//				
//				var t:Number = item.triggerTime || item.y;
//				export.objects[item.id] = {
//					name : item.type, coord:"@@cc.p("+item.x+","+item.y+")@@",
//					time : t
//				};
//			}
//			
//			export.actor = new Object; 
//			var bhs:Object = {};
//			for( var key:String in actors )
//			{
//				if( !this.enemy_bh.hasOwnProperty(key) || this.enemy_bh[key].length == 0 ) {
//					return "【失败】敌人"+key+"未被设置行为";
//				}
//				
//				export.actor[key] = Utils.deepCopy(actors[key]);	
//				export.actor[key].behaviors = this.enemy_bh[key];
//				export.actor[key].triggers = this.enemy_trigger[key] || [];
//				this.enemy_bh[key].forEach(function(item:*, ...args):void {
//					bhs[item] = true;
//				}, null);
//			}
//			
//			export.behavior = new Object;
//			for( var key:String in bhs )
//			{
//				if( !this.bh_lib.hasOwnProperty(key) ) {
//					return "【失败】试图导出不存在的行为"+key;
//				}
//				var raw:String = Utils.genBTreeJS(this.bh_lib[key]);
//				export.behavior[key] = String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
//					""+raw+";}@@");
//			} 
//			
//			export.trap = new Object;
//			for(  var key:* in traps )
//				export.trap[key] = Utils.deepCopy(traps[key]);
//			
//			// export bullet
//			export.bullet = new Object;
//			for( var key:* in this.enemy_profile ) 
//			{
//				if(this.enemy_profile[key].monster_type == "Bullet")
//				{
//					for( var bh:String in export.behavior )
//					{
//						if( export.behavior[bh].search(key) != -1)
//						{
//							export.bullet[key] = this.enemy_profile[key];
//						}
//					}
//				}
//			}
//			
//			// undefined
//			export.luck = new Object;
//			
//			var content:String = JSON.stringify(export, null, "\t");
//			var wrap:String = "function MAKE_LEVEL(){ var level = " + 
//				adjustJS(content) + "; return level; }"; 
//			Utils.write(wrap, this.fullpath("editor/export/level/"+suffix+".js"));
//			
			return null;
		}
		
		private function adjustJS(js:String):String
		{
			var reg1:RegExp = /"@@|@@"/g;
			var result:String = "";
			result = js.replace(reg1, "");
			return result;
		}
		
		public function parseBehaviorXML(data:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b:* in data)
				xml.appendChild(new XML("<behavior label='"+b+"'></behavior>"));
			return xml;
		}
		
//		public function addBehaviors(name:String, data:Object):void
//		{
//			if(!this.bh_lib.hasOwnProperty(name))
//			{
//				if(XMLList(this.bh_xml.behavior).length() == 0)
//					EventManager.getInstance().dispatchEvent(new BehaviorEvent(BehaviorEvent.BT_XML_APPEND));
//				
//				this.bh_lib[name] = data;
//				this.bh_xml.appendChild(new XML("<behavior label='"+name+"'></behavior>"));
//				this.saveLocal();
//			}
//			else
//				trace("addBehaviors error: behavior exists!");
//		}
//		
//		public function updateBehavior(name:String, data:Object):void
//		{
//			this.bh_lib[name] = data;
//			this.saveLocal();
//		}
//		
//		public function renameBehavior(prevName:String, currName:String):void
//		{
//			if(this.bh_lib.hasOwnProperty(currName))
//			{
//				trace("renamebehavior:currname is invalid!");
//				return;
//			}
//			var isChangeEnemyData:Boolean = false;
//			for each(var btData:Array in this.enemy_bh)
//			{
//				var i:int = btData.indexOf(prevName);
//				if(i >= 0)
//				{
//					isChangeEnemyData = true;
//					btData[i] = currName;
//				}
//			}
//			if(isChangeEnemyData) this.saveLocal();
//			this.bh_lib[currName] = this.bh_lib[prevName];
//			delete this.bh_lib[prevName];
//			this.bh_xml = this.parseBehaviorXML(this.bh_lib);
//			this.saveLocal();
//		}
//		
//		public function deleteBehaviors(name:String):void
//		{
//			
//			if(this.bh_lib.hasOwnProperty(name))
//			{
//				var isChangeEnemyData:Boolean = false;
//				for each(var btData:Array in this.enemy_bh)
//				{
//					var i:int = btData.indexOf(name);
//					if(i >= 0)
//					{
//						isChangeEnemyData = true;
//						btData.splice(i, 1);
//					}
//				}
//				if(isChangeEnemyData) this.saveLocal();
//				
//				delete this.bh_lib[name];
//				this.bh_xml = this.parseBehaviorXML(this.bh_lib);
//				this.saveLocal();
//			}
//		}
//		
//		public function addEnemyBehavior(enemyType:String, bName:String):void
//		{
//			if(!this.enemy_bh.hasOwnProperty(enemyType))
//			{
//				trace("addenemybehavior error:enemyType not exist!");
//				return;
//			}
//			var bts:Array = this.enemy_bh[enemyType] as Array;
//			if(enemyContainsBehavior(enemyType, bName))
//			{
//				trace("addenemybehavior error:try to add a behavior that has existed!");
//				return;
//			}
//			bts.push(bName);
//		}
//		
//		public function enemyContainsBehavior(enemyType:String, bName:String):Boolean
//		{
//			var bts:Array = this.enemy_bh[enemyType] as Array;
//			return bts.indexOf(bName) >= 0;
//		}
//		
//		public function setEnemyBehavior(enemyType:String, bName:String):void
//		{
//			if(this.enemy_bh.hasOwnProperty(enemyType))
//			{
//				this.enemy_bh[enemyType] = new Array;
//				if(bName != "")
//					this.enemy_bh[enemyType].push(bName);
//				this.saveLocal();
//			}
//			else
//				trace("set enemy data: enemytype not exist!");
//		}
		/*
		{
			"id": int,
			"path": string,
			"enemies": [
				{
					"type": int,
					"count": int,
					"coins": string,
					"items": string,
				}
			]
		}*/
		
		public function getLevelDataForServer():Array
		{
			var ret:Array = [];
//			for( var ind:* in this.level_list )
//			{
//				var lid:String = this.level_list[ind];
//				var l_path:String = "level/"+lid+".js";
//				var enemies:Object = {};
//				var c:Object =  Data.getChapterDataByLevelId(lid, this.mLevelProfiles);
//				if( !c )
//				{
//					Alert.show("数据出错！");
//				}
//				if ( !(lid in this.levels) )
//				{
//					ret.push( { 
//						id : lid,
//						stageId: c.chapter_id,
//						stage: c.chapter_name,
//						name: c.level_name,
//						path: l_path, enemies : [] });
//					continue;
//				}
//				for( var iter:* in this.levels[lid].data )
//				{
//					var item:Object = this.levels[lid].data[iter];
//					if( !(item.type in enemies) ) 
//					{
//						var m:Object = this.level2monster[lid][item.type];
//						enemies[item.type] = {
//							type 	: int(item.type),
//							count 	: 0,
//							coins 	: m.coins || "",
//							items 	: m.items || ""
//						};
//					}
//					enemies[item.type].count ++;
//				}
//				var l_enemies:Array = [];
//				for each( var mon:* in enemies )
//				{
//					l_enemies.push(mon);
//				}
//				ret.push( {
//					id : lid,
//					path : l_path,
//					stageId: c.chapter_id,
//					stage: c.chapter_name,
//					name: c.level_name,
//					enemies : l_enemies
//				});
//			}
					
			return ret;
		}
		
		public function getCurrentLevelEnemyProfile():Object
		{
			// Utils.dumpObject( this.level2monster );
//			if( this.currSelectedLevel in this.level2monster )
//			{
//				return this.level2monster[this.currSelectedLevel];
//			}
//			trace(this.currSelectedLevel+" can't found");
			return new Array;
		}
//		
//		public function updateLevelById(lid:String, data:Array, endTime:int):Object
//		{
//			var ret:Object = this.getLevelDataById(lid);
//			ret.data = data;
//			ret.endTime = endTime;
//			this.levels[lid] = ret;
//			this.saveLocal();
//			return ret;
//		}
//		
//		public function getLevelDataById(lid:String):Object
//		{
//			var ret:Object = {
//				data : [],
//				endTime : 0
//			};
//			if( lid in this.levels ) return this.levels[lid];
//			this.levels[lid] = ret;
//			return ret;
//		}
//		
//		public function setEnemyTrigger(id:String, triggers:Object):void
//		{
//			this.enemy_trigger[id] = triggers;
//		}
//		
//		// ----------------------------------------------------------------
//		// parse excel 
//		public function parseChapterProfile(profile:File, onComplete:Function):void
//		{
//			var self:Object = this;
//			var excel_reader:ExcelReader = new ExcelReader();
//			excel_reader.parse( profile, function(raw:Object, msg:String=""):void
//			{
//				if( !raw ) onComplete( msg );
//				else {
//					self.mergeChapters( raw );
//					onComplete("成功");
//				}
//			});
//		}
//		
//		private function mergeChapters( raw:Object ):void
//		{
//			for( var key:* in raw )
//				this.mChapter[key] = raw[key];
//					
//			var self:Object = this;
//			//this.updateData(function():void { self.start(); });
//		}
//		
		// ---------------------------------------------------------------------------------
		private function loadJson(file:File, warn:Boolean=true):Object
		{
			var ret:Object = Utils.LoadJSONToObject( file );
			if( !ret && warn)
			{
				Alert.show(file.name+"无法被载入内存或无法被解析！");
				return null;
			}
			return ret;
		}
	}
}