package
{
	import excel.ExcelReader;
	
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
			
			if( !this.mEditorConfigs ) this.mEditorConfigs = { mapSpeed: 32 };
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
		public function setProjectPath(onComplete:Function):void
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
						File.applicationStorageDirectory.resolvePath(item.suffix),
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
		private var mChapterProfiles:Object 	= null;
		
		// --------------------------------------------------------------------------
		public function get chapters():Object { return this.mChapterProfiles; }
		
		public function genLevelXML():XML
		{
			var chapters:Array = [];
			for each(var c:Object in this.mChapterProfiles )
				chapters.push( c );
			chapters.sortOn("id");
			
			var ret:XML = <root></root>;
			for each( var chapter:Object in chapters )
			{
				var node:XML = <node></node>;
				node.@id 	= chapter.id;
				node.@label = chapter.name;
				ret.appendChild( node );
				
				var levels:Array = new Array;
				for each( var l:Object in chapter.levels )
					levels.push( l );
				levels.sortOn("level_id");
				
				for( var i:int =0; i<levels.length; i++ )
				{
					var leaf:XML = <level></level>;
					leaf.@label = levels[i].level_name;
					leaf.@id 	= levels[i].level_id;
					node.appendChild( leaf );
				}
			}
			return ret;
		}
		
		public function makeChapter( id:String, name:String ):void
		{
			if( id in this.mChapterProfiles )
			{
				Alert.show("【创建失败】重复的id");
				return;
			}
			
			mChapterProfiles[id] = {
				id : id,
				name : name,
				levels : {}
			};
		}
		
		public function deleteChapter( id:String ):void
		{
			if( !(id in this.mChapterProfiles) ) return;
			for( var key:String in this.mChapterProfiles[id].levels )
			{
				var PROFILE:File = this.resolvePath("saved/profile/"+key+".json");
				if( PROFILE.exists ) PROFILE.deleteFile();
			}
			delete this.mChapterProfiles[id];
		}
		
		public function makeLevel( chapter_id:String, id:String, name:String ):void
		{
			if( !(chapter_id in this.mChapterProfiles) )
			{
				Alert.show("【创建失败】章节id不存在");
				return;
			}
			
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( id in chapter.levels )
				{
					Alert.show("【创建失败】关卡id已存在");
					return;
				}
			}
			
			var level:Object = {
				chapter_id : chapter_id,
				chapter_name : this.mChapterProfiles[chapter_id].name,
				level_id : id,
				level_name : name,
				monsters : {}
			};
			
			this.mChapterProfiles[chapter_id].levels[id] = level;
			this.writeToProfile( id, level );
		}
		
		public function deleteLevel( id:String ):void
		{
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( id in chapter.levels )
				{
					delete chapter.levels[id];
					var PROFILE:File = this.resolvePath("saved/profile/"+id+".json");
					if( PROFILE.exists ) PROFILE.deleteFile();
					return;
				}
			}
		}
		
		public function getLevelData( lid:String ):Object 
		{
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( lid in chapter.levels ) return chapter.levels[lid];
			}
			return null;
		}
		
		private function writeToProfile( lid:String, data:Object ):void
		{
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/profile/"+lid+".json" ),
				data
			);
		}
		
		///////////////////////////////////////////////////////////////////////
		////// level data
		// the validity of data below is responsible to upper class
		private var mLevelInstancesTable:Object = null;
		
		private var mBehaviorSet:Object 		= null;
		private var mFormationSet:Object 		= null;
		private var mDecoSet:Object				= null;
		private var mDecoCellSet:Object 		= null;
		private var mDecoBgSet:Object			= null;
		private var mDecoGroupSet:Object	= null;
		
		// --------------------------------------------------------------------------
		public function getFirstLevelId():String
		{
			var min:String = "99999999999"; 
			for( var item:* in this.mLevelInstancesTable )
			{
				if( int(item) < int(min) ) min = item;
			}
			return min;
		}
		public function getLevelDataById( lid:String ):Object
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			return this.mLevelInstancesTable[lid].data;
		}
		
		public function updateLevelDataById( lid:String, inst:Object ):void
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			this.mLevelInstancesTable[lid].data = inst;
			this.writeToLevel( lid );
		}
		
		public function getEnemyBehaviorsById( lid:String, eid:String ):Object
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			return this.mLevelInstancesTable[lid].behavior[eid] || [];
		}
		
		public function updateEnemyBehaviorsById( lid:String, eid:String, bhs:Array ):void
		{	
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			this.mLevelInstancesTable[lid].behavior[eid] = bhs;
			this.writeToLevel( lid );
		}
		
		public function findEnemiesByBehavior(lid:String, behaviorName:String ): Array
		{
			var list:Array = [];
			var behaviorTable:Object = mLevelInstancesTable[lid].behavior;
			
			for(var x:* in behaviorTable)
			{
				if(behaviorTable[x])
				{
					if((behaviorTable[x] as Array).indexOf(behaviorName) != -1)
						list.push(x);
				}
			}
			
			return list;
		}
		
		public function getEnemyTriggersById( lid:String, eid:String ):Object
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			return this.mLevelInstancesTable[lid].trigger[eid];
		}
		
		public function updateEnemyTriggersById( lid:String, eid:String, triggers:Object ):void
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					data : [], behavior : {}, trigger : {}
				};
			
			this.mLevelInstancesTable[lid].trigger[eid] = triggers;
			this.writeToLevel( lid );
		}
		
		private function writeToLevel( lid:String ):void
		{
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/level/"+lid+".json" ),
				this.mLevelInstancesTable[lid]
			);
		}
		
		public function get behaviorSet():Object { return this.mBehaviorSet; }
		public function get decoSet():Object { return this.mDecoSet; }
		public function get decoBgSet():Object { return this.mDecoBgSet; }
		public function get decoCellSet():Object { return this.mDecoCellSet; }
		public function get decoGroupSet():Object { return this.mDecoGroupSet; }
		
		public function getBehaviorById( bid:String ):Object
		{
			return this.mBehaviorSet[bid];
		}
		public function eraseBehaviorById( bid:String ):void
		{
			delete this.mBehaviorSet[bid];
			var file:File = this.resolvePath( "saved/behavior/"+bid+".json" );
			if( file.exists ) 
				file.deleteFile();
		}
		public function updateBehaviorSetById( bid:String, data:Object ):void
		{
			this.mBehaviorSet[bid] = data;
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/behavior/"+bid+".json" ),
				this.mBehaviorSet[bid]
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
			var file:File = this.resolvePath( "saved/format/"+fid+".json" );
			if( file.exists ) file.deleteFile();
			Runtime.getInstance().onFormationDataChange();
		}
		public function updateFormationSetById( fid:String, data:Object):void
		{
			this.mFormationSet[fid] = data;
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath("saved/format/"+fid+".json"),
				this.mFormationSet[fid]
			);
			Runtime.getInstance().onFormationDataChange();
		}
		
		private function merge(to:Object, from:Object):void
		{
			for( var key:* in from )
			{
				if( key in to ) trace(" collision happened at "+key );
				to[key] = from[key];
			}
		}
		
		private function parseLocalData(onComplete:Function):void
		{
			this.mDynamicArgs = this.loadJson(
				File.applicationStorageDirectory.resolvePath("dynamic_args.json"), false
			) as Object || {};
			
			this.mBehaviorNode = this.loadJson(
				File.applicationStorageDirectory.resolvePath("bt_node_format.json"), false
			) as Object || {};
			
			this.mChapterProfiles = {};
			var PROFILE:File = this.resolvePath("saved/profile");
			if( PROFILE.exists && PROFILE.isDirectory )
			{
				var profiles:Array = PROFILE.getDirectoryListing();
				for each(var file:File in profiles)
				{
					if( file.name.split(".")[1] != "json" )
						continue;
					var name:String = file.name.split(".")[0];
					var to:Object = Utils.LoadJSONToObject( file );
					
					if( !(to.chapter_id in this.mChapterProfiles) )
						this.makeChapter( to.chapter_id, to.chapter_name );
					
					this.mChapterProfiles[to.chapter_id].levels[to.level_id] 
						= Utils.LoadJSONToObject( file );
				}
			}
			// chapter profiles

			
			this.mLevelInstancesTable = {};
			var LEVEL:File = this.resolvePath("saved/level");
			if( LEVEL.exists && LEVEL.isDirectory )
			{
				var levels:Array = LEVEL.getDirectoryListing();
				for each( file in levels )
				{
					if( file.name.split(".")[1] != "json" )
						continue;
					name = file.name.split(".")[0];
					to = {}; 
					to[name] = Utils.LoadJSONToObject( file );
					
					this.merge( this.mLevelInstancesTable,  to );
				}
				
			}
			
			this.mBehaviorSet = {};
			var BEHAVIOR:File = this.resolvePath( "saved/behavior" );
			if( BEHAVIOR.exists && BEHAVIOR.isDirectory )
			{
				var bhs:Array = BEHAVIOR.getDirectoryListing();
				for each( file in bhs )
				{
					if( file.name.split(".")[1] != "json" )
						continue;
					name = file.name.split(".")[0];
					to = {};
					to[name] = Utils.LoadJSONToObject( file );
					
					this.merge( this.mBehaviorSet, to );
				}
			}
			
			this.mFormationSet = {};
			var FORMAT:File = this.resolvePath( "saved/format" );
			if( FORMAT.exists && FORMAT.isDirectory )
			{
				var formats:Array = FORMAT.getDirectoryListing();
				for each( file in formats )
				{
					if( file.name.split(".")[1] != "json" )
						continue;
					name = file.name.split(".")[0];
					to = {};
					to[name] = Utils.LoadJSONToObject( file );
					
					this.merge( this.mFormationSet, to );
				}
			}
			
			this.mDecoSet = {};
			this.mDecoCellSet = {};
			this.mDecoBgSet = {};
			this.mDecoGroupSet = {};
			var decoBg:File = this.resolvePath( "images/bg" );
			var decoCell:File = this.resolvePath( "images" );
			var decoSet:File = this.resolvePath( "saved/deco" );
			var decoGroup:File = this.resolvePath("saved/deco/group");
			if (decoBg.exists && decoBg.isDirectory) {
				var list:Array = decoBg.getDirectoryListing();
				for each (file in list) {
					if (file.name.split(".")[1] == "png") {
						this.mDecoBgSet[file.name.split(".")[0]] = 1;
					}
				}
			}
			if (decoCell.exists && decoCell.isDirectory) {
				list = decoCell.getDirectoryListing();
				for each (file in list) {
					if (file.name.split(".")[1] == "png") {
						this.mDecoCellSet[file.name.split(".")[0]] = 1;
					}
				}
			}
			if (decoSet.exists && decoSet.isDirectory) {
				list = decoSet.getDirectoryListing();
				for each (file in list) {
					if (file.name.split(".")[1] == "json") {
						this.mDecoSet[file.name.split(".")[0]] = Utils.LoadJSONToObject(file);
					}
				}
			}
			if (decoGroup.exists && decoGroup.isDirectory) {
				list = decoGroup.getDirectoryListing();
				for each (file in list) {
					if (file.name.split(".")[1] == "json") {
						this.mDecoGroupSet[file.name.split(".")[0]] = Utils.LoadJSONToObject(file);
					}
				}
			}
			
			this.updateEditorData( onComplete );
		}
		
		///////////////////////////////////////////////////////////////////////
		////// second-hand data of editor
		private var mEnemySkins:Dictionary 		= new Dictionary;
		private var mEnemyProfilesTable:Object 	= null;
		
		private var mLevelId2Enemies:Object 	= null;
		
		// --------------------------------------------------------------------------
		
		public function getSkinById( fid:String ):* 
		{
			return this.mEnemySkins[fid];	
		}
		public function getEnemyProfileById( eid:String ):Object
		{
			return this.mEnemyProfilesTable[eid];
		}
		public function getEnemiesByLevelId( lid:String ):Object
		{
			return this.mLevelId2Enemies[lid];
		}
			
		private function updateEditorData(onComplete:Function):void
		{
			this.mEnemyProfilesTable = DataParser.genMonstersTable( this.mChapterProfiles );
			this.mLevelId2Enemies    = DataParser.genLevel2MonsterTable( this.mChapterProfiles );
			
			// load skins async
			//this.mEnemySkins 	     = new Dictionary();
			
			var self:Data = this;
			var length:Number = 0, countor:Number = 0; 
			var callback:Function = function():void
			{
				Runtime.getInstance().onProfileDataChange();
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
			
			for each(var item:Object in this.mEnemyProfilesTable)
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
			for( var lid:String in this.mLevelInstancesTable )
			{
				var data:Array = this.mLevelInstancesTable[lid].data || [];
				var triggers:Object = this.mLevelInstancesTable[lid].trigger || {};
				var bhs:Object = this.mLevelInstancesTable[lid].behavior || {};
				
				var monsters:Object = this.mLevelId2Enemies[lid] || {};
				for( var iter:int = data.length-1; iter>=0; iter-- )
				{
					if( !(data[iter].type in monsters) && 
						  data[iter].type != "AreaTrigger" )
					{
						result += "【删除】敌人"+data[iter].type+"未被关卡"+lid+"定义\n";
						data.splice( iter, 1 );
					}
				}
				
				for( iter = triggers.length-1; iter>=0; iter-- )
				{
					if( !(iter in monsters) ) delete triggers[iter];
				}
				
				for( iter = bhs.length-1; iter>=0; iter-- )
				{
					if( !(iter in monsters) )
					{
						delete bhs[iter];
						continue;
					}
					for( var j:int=bhs[iter].length-1; j>=0; j-- )
					{
						if( !this.mBehaviorSet.hasOwnProperty(bhs[iter][j]) )
						{
							result += "【删除】行为"+bhs[iter][j]+"不存在\n";
							bhs[iter].splice( j, 1 );
						}
					}
				}
			}
			
			delete this.mLevelInstancesTable["null"];
	
			return result;
		}
		
		public function exportLevelJS(lid:String, suffix:String):String
		{	
			if( !(lid in this.mLevelInstancesTable ) ) return "【失败】无相关地图数据存在";
				
			var export:Object = new Object;
			var source:Array = this.mLevelInstancesTable[lid].data;
			
			// confs
			export.map = { speed : this.mEditorConfigs.mapSpeed };
			
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

				var data:Object = this.mEnemyProfilesTable[item.type];
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
				if( !this.mLevelInstancesTable[lid].behavior.hasOwnProperty(key) ||
					this.mLevelInstancesTable[lid].behavior[key].length == 0 )
				{
					return "【失败】敌人"+key+"未被设置行为";
				}
				
				export.actor[key] = Utils.deepCopy(actors[key]);	
				export.actor[key].behaviors = this.mLevelInstancesTable[lid].behavior[key];
				export.actor[key].triggers = this.mLevelInstancesTable[lid].trigger[key] || [];
				this.mLevelInstancesTable[lid].behavior[key].forEach(
					function(item:*, ...args):void {
						bhs[item] = true;
					}, 
				null);
			}

			export.behavior = new Object;
			for( key in bhs )
			{
				if( !this.mBehaviorSet.hasOwnProperty(key) ) {
					return "【失败】试图导出不存在的行为"+key;
				}
				var raw:String = Utils.genBTreeJS(Utils.cloneObjectData(this.mBehaviorSet[key]));
				export.behavior[key] = String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
					""+raw+";}@@");
			} 
			
			export.trap = new Object;
			for( key in traps )
				export.trap[key] = Utils.deepCopy(traps[key]);
			
			// export bullet
			export.bullet = new Object;
			for( key in this.mEnemyProfilesTable ) 
			{
				if(this.mEnemyProfilesTable[key].monster_type == "Bullet")
				{
					for( var bh:String in export.behavior )
					{
						if( export.behavior[bh].search(key) != -1)
						{
							export.bullet[key] = this.mEnemyProfilesTable[key];
						}
					}
				}
			}
			
			// undefined
			export.luck = new Object;
			
			var content:String = JSON.stringify(export, null, "\t");
			var wrap:String = "function MAKE_LEVEL(){ var level = " + 
				adjustJS(content) + "; return level; }"; 
			
			Utils.WriteRawFile( this.resolvePath("export/level/"+suffix+".js"), wrap );
			return null;
		}
		
		private function adjustJS(js:String):String
		{
			var reg1:RegExp = /"@@|@@"/g;
			var result:String = "";
			result = js.replace(reg1, "");
			return result;
		}
		
		public function getLevelDataForServer( lid:String ):Object
		{	
			var profile:Object = null;
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( lid in chapter ) 
				{
					profile = chapter.levels[lid];
					break;
				}
 			}
			if( !profile ) return null;
	
			if( !(lid in this.mLevelInstancesTable) ) 
				return { 
					id : lid,
					stageId: profile.chapter_id,
					stage: profile.chapter_name,
					name: profile.level_name,
					path: "level/"+lid+".js", enemies : [] 
				};
			
			var inst:Object = this.mLevelInstancesTable[lid];
			var enemies:Object = {};
			for each( var item:* in inst.data ) 
			{
				if( item.type == "AreaTrigger" ) continue;
				if( !(item.type in enemies) ) {
					var m:Object = this.mLevelId2Enemies[lid][item.type];
					enemies[item.type] = {
						type 	: int(item.type),
						count 	: 0,
						coins 	: m.coins || "",
						items 	: m.items || ""
					};
				}
				enemies[item.type].count ++;
			}
			
			var array:Array = [];
			for each( var monster:* in enemies )
				array.push( monster );
			
			return {
				id : lid,
				stageId: profile.chapter_id, stage: profile.chapter_name,
				name: profile.level_name, path: "level/"+lid+".js", 
				enemies : array
			};
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