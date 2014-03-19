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
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	import excel.ExcelReader;
	
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
		public function init(onComplete:Function):void {
			var self:Data = this;
			self.start( function(m1:String):void
			{
				self.syncClient( function(m2:String):void
				{
					self.parseLocalData( function(m3:String):void
					{
						onComplete( m1+"\n"+m2+"\n"+m3 );
					});
				});
			});
		}
		
		///////////////////////////////////////////////////////////////////////
		////// editor configs 
		// projectPath 	-> root directroy of data
		// speed 		-> speed & scale factor of map view
		private var mEditorConfigs:Object = null;
		private var mProjectRoot:File = null;
		// --------------------------------------------------------------------------
		public function start(onComplete:Function):void {
			var config:File = File.applicationStorageDirectory.resolvePath("conf.json");
			this.mEditorConfigs = this.loadJson(config, false);
			
			if( !this.mEditorConfigs ) this.mEditorConfigs = { speed: 32 };
			if( !this.mEditorConfigs.projectPath ) {
				var self:* = this;
				this.setProjectPath( function(file:File):void
				{
					self.mProjectRoot = file;
					onComplete("【成功】工程文件夹路径指定");
				} );
			}
			else 
			{
				this.mProjectRoot = new File( this.mEditorConfigs.projectPath );
				onComplete("【成功】工程文件夹路径指定");
			}
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
		public function resolvePath(sub:String):File
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
			var self:Data = this, counter:Number = 0, error:Boolean = false;
			var alldone:Function = function(item:Object):Function
			{
				var handleTEXT:Function = function(e:Event):void
				{
					MapEditor.getInstance().addLog("下载"+item.suffix+"成功");
					Utils.WriteRawFile(
						self.resolvePath("data/"+item.suffix),
						e.target.data
					);
					
					if( ++counter >= kSYNC_TARGETS.length && !error )
						onComplete("【成功】同步客户端数据文件");
				}
				return handleTEXT;
			}
			var anyerror:Function = function():void
			{
				error = true;
				MapEditor.getInstance().addLog("下载失败");
				onComplete("【错误】同步OSS客户端数据出错…");
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
		////// profiles
		private var mLevelProfiles:Object 		= null;
		
		// --------------------------------------------------------------------------
		public function mergeLevelProfile( file:File, onComplete:Function ):void
		{
			var self:Data = this;
			var excel_reader:ExcelReader = new ExcelReader();
			excel_reader.parse( file, function( raw:Object, msg:String="" ):void
			{
				if( !raw ) onComplete(msg);
				else {
					
					// merge 
					for( var key:* in raw ) this.mLevelProfiles[key] = raw[key];
					Utils.WriteObjectToJSON( // persistence
						this.resolvePath( "saved/profiles.json" ),
						this.mLevelProfiles
					);
					
					// update
					this.updateEditorData( function(msg:String):void
					{
						onComplete(msg+"\n【成功】更新关卡配置");
					});
				}
			});
		}
		
		///////////////////////////////////////////////////////////////////////
		////// level data
		// the validity of data below is responsible to upper class
		private var mLevelInstancesTable:Object = null;
		
		private var mEnemyBehaviorsTable:Object = null;
		private var mEnemyTriggersTable:Object 	= null;
		
		private var mBehaviorSet:Object 		= null;
		private var mFormationSet:Object 		= null;
		
		// --------------------------------------------------------------------------
		public function getFirstLevelId():String
		{
			for( var item:* in this.mLevelInstancesTable )
				return item;
			return "undefined";
		}
		public function getLevelDataById( lid:String ):Object
		{
			return this.mLevelInstancesTable[lid];
		}
		
		public function updateLevelDataById( lid:String, inst:Object ):void
		{
			this.mLevelInstancesTable[lid] = inst;
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/levels.json" ),
				this.mLevelInstancesTable
			);
		}
		
		public function getEnemyBehaviorsById( eid:String ):Object
		{
			return this.mEnemyBehaviorsTable[eid];
		}
		
		public function updateEnemyBehaviorsById( eid:String, bhs:Object ):void
		{
			this.mEnemyBehaviorsTable[eid] = bhs;
			Utils.WriteObjectToJSON(
				this.resolvePath( "saved/enemy_bh.json" ),
				this.mEnemyBehaviorsTable
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
				this.resolvePath( "saved/enemy_trigger.json" ),
				this.mEnemyTriggersTable
			);
		}
		
		public function get behaviorSet():Object { return this.mBehaviorSet; } 
		public function getBehaviorById( bid:String ):Object
		{
			return this.mBehaviorSet[bid];
		}
		public function eraseBehaviorById( fid:String ):void
		{
			delete this.mBehaviorSet[fid];
			this.writeBehaviors();
		}
		public function updateBehaviorSetById( bid:String, data:Object ):void
		{
			this.mBehaviorSet[bid] = data;
			this.writeBehaviors();
		}
		private function writeBehaviors():void
		{
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/bh_lib.json" ),
				this.mBehaviorSet
			);			
		}
		
		public function get formationSet():Object { return this.mFormationSet; }
		public function getFormationById( fid:String ):Object
		{
			return this.mFormationSet[fid];
		}
		public function eraseFormationById( fid:String ):void
		{
			delete this.mFormationSet[fid];
			this.writeFormations();
		}
		public function updateFormationSetById( fid:String, data:Object):void
		{
			this.mFormationSet[fid] = data;
			this.writeFormations();
		}
		private function writeFormations():void
		{
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath("saved/formations.json"),
				this.mFormationSet
			);			
			Runtime.getInstance().onFormationDataChange();
		}
		
		private function parseLocalData(onComplete:Function):void
		{
			this.mDynamicArgs = this.loadJson(
				this.resolvePath("data/dynamic_args.json"), false
			) as Object || {};
			
			this.mBehaviorNode = this.loadJson(
				this.resolvePath("data/bt_node_format.json"), false
			) as Object || {};
			
			this.mLevelProfiles = this.loadJson(
				this.resolvePath("saved/profiles.json"), false
			) as Object || {};
			
			this.mLevelInstancesTable = this.loadJson( 
				this.resolvePath("saved/levels.json"), false 
			) as Object || {};
			
			this.mEnemyBehaviorsTable = this.loadJson(
				this.resolvePath("saved/enemy_bh.json"), false
			) as Object || {};
			
			this.mEnemyTriggersTable = this.loadJson(
				this.resolvePath("saved/enemy_trigger.json"), false
			) as Object || {};
			
			this.mBehaviorSet = this.loadJson(
				this.resolvePath("saved/bh_lib.json"), false
			) as Object || {};
			
			this.mFormationSet = this.loadJson(
				this.resolvePath("saved/formations.json"), false
			) as Object || {};
			
			this.updateEditorData( onComplete );
		}
		
		///////////////////////////////////////////////////////////////////////
		////// second-hand data of editor
		private var mEnemySkins:Dictionary 		= null;
		private var mEnemyProfilesTalbe:Object 	= null;
		
		private var mLevelId2Enemies:Object 	= null;
		private var mLevelXML:XML 				= null;
		
		// --------------------------------------------------------------------------
		
		public function getSkinById( fid:String ):* 
		{
			return this.mEnemySkins[fid];	
		}
		public function getEnemyProfileById( eid:String ):Object
		{
			return this.mEnemyProfilesTalbe[eid];
		}
		public function getEnemiesByLevelId( lid:String ):Object
		{
			return this.mLevelId2Enemies[lid];
		}
		public function get levelXML():XML { return this.mLevelXML; }
			
		private function updateEditorData(onComplete:Function):void
		{
			this.mEnemyProfilesTalbe = DataParser.genMonstersTable( this.mLevelProfiles );
			this.mLevelId2Enemies    = DataParser.genLevel2MonsterTable( this.mLevelProfiles );
			this.mLevelXML 			 = DataParser.genLevelXML( this.mLevelProfiles );
			
			// load skins async
			this.mEnemySkins 	     = new Dictionary();
			
			var self:Data = this;
			var length:Number = 0, countor:Number = 0; 
			var callback:Function = function():void
			{
				var msg:String = self.validityCheckAndCleanUp();
				onComplete( msg + "\n【成功】载入"+length+"个图像资源\n");
			}
			
			var alldone:Function = function(face:String):Function
			{
				return function(e:Event):void
				{
					var loader:Loader = (e.target as LoaderInfo).loader; 
					self.mEnemySkins[face] = Bitmap(loader.content).bitmapData;
					MapEditor.getInstance().addLog("加载"+face+"成功");
					if( ++countor >= length ) {
						MapEditor.getInstance().addLog("全部skin加载完成");
						callback();
					}
				}
			}
			
			for each(var item:Object in this.mEnemyProfilesTalbe)
			{
				var face:String = item.face;
				if( this.mEnemySkins.hasOwnProperty(face) ) continue;
				this.mEnemySkins[face] = "icu";
				
				var bytes:ByteArray = new ByteArray;
				var file:File = this.resolvePath("skins/"+face+".png");
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
					onComplete("【失败】加载图像"+face+"失败");
				});
				loader.loadBytes(bytes);
				MapEditor.getInstance().addLog("加载"+face+"从"+file.nativePath+"..");
			}	
			
			if( length == 0 ) callback();
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
	
			return result;
		}
		
		
		public function exportJS( lid:String ):String
		{	
			var msg:String = this.exportLevelJS( lid, lid );
			
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
			if( !(lid in this.mLevelInstancesTable ) ) return "【失败】无相关地图数据存在";
				
			var export:Object = new Object;
			var source:Array = this.mLevelInstancesTable[lid].data;
			
			// confs
			export.map = { speed : this.mEditorConfigs.speed };
			
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

				var data:Object = this.mEnemyProfilesTalbe[item.type];
				if( data.monster_type == "Bullet" ) {
					return "【失败】子弹类型不可被放置在地图中"; 
				}
				if( data.monster_type == "Monster" ) actors[item.type] = data;
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
				if( !this.mEnemyBehaviorsTable.hasOwnProperty(key) || this.mEnemyBehaviorsTable[key].length == 0 ) {
					return "【失败】敌人"+key+"未被设置行为";
				}
				
				export.actor[key] = Utils.deepCopy(actors[key]);	
				export.actor[key].behaviors = this.mEnemyBehaviorsTable[key];
				export.actor[key].triggers = this.mEnemyTriggersTable[key] || [];
				this.mEnemyBehaviorsTable[key].forEach(function(item:*, ...args):void {
					bhs[item] = true;
				}, null);
			}

			export.behavior = new Object;
			for( key in bhs )
			{
				if( !this.mBehaviorSet.hasOwnProperty(key) ) {
					return "【失败】试图导出不存在的行为"+key;
				}
				var raw:String = Utils.genBTreeJS(this.mBehaviorSet[key]);
				export.behavior[key] = String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
					""+raw+";}@@");
			} 
			
			export.trap = new Object;
			for( key in traps )
				export.trap[key] = Utils.deepCopy(traps[key]);
			
			// export bullet
			export.bullet = new Object;
			for( key in this.mEnemyProfilesTalbe ) 
			{
				if(this.mEnemyProfilesTalbe[key].monster_type == "Bullet")
				{
					for( var bh:String in export.behavior )
					{
						if( export.behavior[bh].search(key) != -1)
						{
							export.bullet[key] = this.mEnemyProfilesTalbe[key];
						}
					}
				}
			}
			
			// undefined
			export.luck = new Object;
			
			var content:String = JSON.stringify(export, null, "\t");
			var wrap:String = "function MAKE_LEVEL(){ var level = " + 
				adjustJS(content) + "; return level; }"; 
			
			Utils.WriteRawFile( this.resolvePath("/export/level/"+suffix+".js"), wrap );
			return null;
		}
		
		private function adjustJS(js:String):String
		{
			var reg1:RegExp = /"@@|@@"/g;
			var result:String = "";
			result = js.replace(reg1, "");
			return result;
		}
		
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