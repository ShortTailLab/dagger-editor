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
	import flash.net.dns.AAAARecord;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.utils.object_proxy;
	
	import excel.ExcelReader;
	
	import mapEdit.Entity;
	import mapEdit.SectionManager;
	
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
		
		// create a new chapter entry
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
		
		// update chapter related meta info.
		public function updateChapter( id:String, data:Object ):void
		{
			if( !("chapter_id" in data) || !("chapter_name" in data) )
				return;
			
			if( data.chapter_id in this.mChapterProfiles && data.chapter_id != id ) 
			{
				Alert.show("【失败】章节id已存在");
				return;
			}
			if( !(id in this.mChapterProfiles) ) 
				return;
			
			
			for( var key:String in this.mChapterProfiles[id].levels )
			{
				this.mChapterProfiles[id].levels[key].chapter_id = data.chapter_id;
				this.mChapterProfiles[id].levels[key].chapter_name = data.chapter_name;
				this.writeToProfile(key, this.mChapterProfiles[id].levels[key]);
			}
			
			mChapterProfiles[id].name 	= data.chapter_name;
			mChapterProfiles[id].id 	= data.chapter_id;
			
			if( id != data.chapter_id )
			{
				mChapterProfiles[data.chapter_id] = mChapterProfiles[id];
				delete mChapterProfiles[id];
			}
		}
		
		public function deleteChapter( id:String ):void
		{
			if( !(id in this.mChapterProfiles) ) return;
			
			if( Runtime.getInstance().currentLevelID in this.mChapterProfiles[id] )
			{
				Runtime.getInstance().currentLevelID = null;
			}
			
			for( var key:String in this.mChapterProfiles[id].levels )
			{
				var PROFILE:File = this.resolvePath("saved/profile/"+key+".json");
				if( PROFILE.exists ) PROFILE.deleteFile();
			}
			delete this.mChapterProfiles[id];
		}
		
		// create a level entry
		public function makeLevel( chapter_id:String, id:String, data:Object ):void
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
				monsters : {}
			};
			
			for( var key:String in data )
			{
				level[key] = data[key];
			}
			
			this.mChapterProfiles[chapter_id].levels[id] = level;
			this.writeToProfile( id, level );
		}
		
		// update level profile
		public function updateLevel( id:String, data:Object ):void
		{
			var level:Object = this.getLevelProfileById( id );
			if( !level ) 
				return;
			
			if( "chapter_id" in data )
			{
				if( !(data.chapter_id in this.mChapterProfiles) )
				{
					Alert.show("【创建失败】章节id不存在");
					return;
				}
				
				if( this.mChapterProfiles[level.chapter_id].levels[id] != level )
				{
					this.mChapterProfiles[data.chapter_id].levels[id] = level;
					delete this.mChapterProfiles[level.chapter_id].levels[id];
				}
			}
			
			for( var key:String in data )
			{
				if(key == "level_id")
					continue;
				level[key] = data[key];
			}
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
			
			if( Runtime.getInstance().currentLevelID == id )
			{
				Runtime.getInstance().currentLevelID = null;
			}
		}
		
		
		public function makeMonster( level_id:String, id:String, data:Object):void
		{
			var level:Object = this.getLevelProfileById( level_id );
			if( !level ) {
				Alert.show("【创建失败】关卡id不存在 ");
				return;
			}
			
			if( "monster_id" in data ) 
				id = data.monster_id;
			
			if( id in level.monsters || !id )
			{
				Alert.show("【创建失败】怪物id已经存在");
				return;
			}
			
			var monster:Object = {
				monster_id : id
			};
			for( var key:String in data )
				monster[key] = data[key];
			
			level.monsters[id] = monster;
			this.writeToProfile( level_id, level );
			
			Runtime.getInstance().onProfileDataChange();
		}
		
		public function updateMonster( level_id:String, id:String, data:Object):void
		{
			var level:Object = this.getLevelProfileById( level_id );
			if( !level ) {
				Alert.show("【创建失败】关卡id不存在 ");
				return;
			}
			
			if( !(id in level.monsters) || !id )
			{
				Alert.show("【创建失败】怪物不存在");
				return;
			}
			
			var monster:Object = level.monsters[id];
			
			if( "monster_id" in data && 
				data.monster_id in level.monsters &&
				level.monsters[data.monster_id] != monster )
			{
				Alert.show("【创建失败】怪物id已经存在");
				return;
			}
			
			for( var key:String in data )
				monster[key] = data[key];
			level.monsters[monster.monster_id] = monster;
			
			this.writeToProfile( level_id, level );
			Runtime.getInstance().onProfileDataChange();
		}
		
		public function eraseMonster( level_id:String, id:String ):void
		{
			var profile:Object = this.getLevelProfileById( level_id );
			if( !profile ) {
				Alert.show("【创建失败】关卡id不存在 ");
				return;
			}
			
			if( !(id in profile.monsters) || !id )
			{
				Alert.show("【创建失败】怪物不存在");
				return;
			}
			
			// clean up
			delete profile.monsters[id];
			this.writeToProfile( level_id, profile );
			Runtime.getInstance().onProfileDataChange();
		}
		
		
		public function getLevelProfileById( lid:String ):Object 
		{
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( lid in chapter.levels ) 
					return chapter.levels[lid];
			}
			return null;
		}
		
		public function getChapterProfileById( lid:String ):Object
		{
			for each( var chapter:Object in this.mChapterProfiles )
			{
				if( lid in chapter.levels ) 
					return chapter;
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
		
		public function getLevelById( lid:String ):Object
		{
			if( !(lid in this.mLevelInstancesTable) )
				this.mLevelInstancesTable[lid] = {
					sections : [], behavior : {}, trigger : {}, config : {}
				};
			return this.mLevelInstancesTable[lid];
		}
		
		public function getLevelDataById( lid:String ):Array
		{
			return this.getLevelById( lid ).sections || [];
		}
		
		public function updateLevelDataById( lid:String, inst:Array ):void
		{
			this.getLevelById( lid ).sections = inst;
			this.writeToLevel( lid );
		}
		
		public function updateLevelConfigsById( lid:String, inst:Object ):void
		{
			this.getLevelById( lid ).config = inst;
			this.writeToLevel( lid );
		}
		
		public function getLevelConfigsById( lid:String ):Object
		{
			return this.getLevelById(lid).config || {};
		}
		
		public function getEnemyBehaviorsById( lid:String, eid:String ):Object
		{
			var level:Object = this.getLevelById( lid );
			if( !(eid in level.behavior ) ) level.behavior[eid] = [];
			return level.behavior[eid];
		}
		
		public function updateEnemyBehaviorsById( lid:String, eid:String, bhs:Array ):void
		{	
			this.getLevelById( lid ).behavior[eid] = bhs;
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
			var level:Object = this.getLevelById( lid );
			if( !(eid in level.trigger) ) level.trigger[eid] = {};
			return level.trigger[eid];
		}
		
		public function updateEnemyTriggersById( lid:String, eid:String, triggers:Object ):void
		{
			this.getLevelById( lid ).trigger[eid] = triggers;
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
		public function get decoGroupSet():Object { return this.mDecoGroupSet; }
		public function get decoBgSet():Object { return this.mDecoBgSet; }
		public function get decoCellSet():Object { return this.mDecoCellSet; }
		
		public function eraseDecoSetById(id:String):void {
			delete this.mDecoSet[id];
			var file:File = this.resolvePath( "saved/deco/"+id+".json" );
			if( file.exists ) 
				file.deleteFile();
		}
		public function updateDecoSetById(id:String, data:Object):void {
			this.mDecoSet[id] = data;
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/deco/"+id+".json" ),
				this.mDecoSet[id]
			);
		}
		public function eraseDecoGroupSetById(id:String):void {
			delete this.mDecoGroupSet[id];
			var file:File = this.resolvePath( "saved/deco/group/"+id+".json" );
			if( file.exists ) 
				file.deleteFile();
		}
		public function updateDecoGroupSetById(id:String, data:Object):void {
			this.mDecoGroupSet[id] = data;
			Utils.WriteObjectToJSON( // persistence
				this.resolvePath( "saved/deco/group/"+id+".json" ),
				this.mDecoGroupSet[id]
			);
		}
		
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
			
			this.loadImage( onComplete );
		}
		
		///////////////////////////////////////////////////////////////////////
		////// second-hand data of editor
		private var mEnemySkins:Dictionary 		= new Dictionary;
		// --------------------------------------------------------------------------
		public function get skins():Dictionary { return this.mEnemySkins; }
		
		public function getSkinById( fid:String ):* 
		{
			return this.mEnemySkins[fid];
		}
		
		public function getEnemyProfileById( lid:String, mid:String ):Object
		{
			if( !lid || !mid ) return null;
			var profile:Object = this.getLevelProfileById( lid );
			if( !profile ) return null;
			return profile.monsters[mid];
		}
		
		public function isMonster( type:String ):Boolean
		{
			if(EditMonster.isCustomBehaviorType(type))
				return true;
			
			for each( var item:String in (this.mDynamicArgs.MonsterType || {}) )
			{
				if( type == item ) return true;
			}
			
			return false;
		}
		
		public function isBullet( type:String ):Boolean
		{
			for each( var item:String in (this.mDynamicArgs.BulletType || {}) )
			{
				if( type == item ) return true;
			}
			
			return false;
		}
		
		public function isTrap( type:String ):Boolean
		{
			for each( var item:String in (this.mDynamicArgs.TrapType || {}) )
			{
				if( type == item ) return true;
			}
			
			return false;
		}
		
		public function typeToProfileType(type:String):String
		{
			if(Data.getInstance().isMonster(type))
				return "MonsterProfile";
			else if(Data.getInstance().isBullet(type))
				return "BulletProfile";
			else if(Data.getInstance().isTrap(type))
				return "TrapProfile";
			throw "Unknown object type";
		}
		
		public function isTrigger( type:String ):Boolean
		{
			return type == SectionManager.TRIGGER_TYPE;
		}
	
		public function getTrapsByLevelId( lid:String ):Object 
		{
			var level:Object = this.getLevelProfileById( lid );
			if( !level ) return null;
			
			var ret:Object = {};
			for each( var monster:Object in level.monsters )
			{
				if( this.isTrap(monster.type) )
				{
					ret[monster.monster_id] = monster;
				}
			}
			return ret;
		}
		
		public function getEnemiesByLevelId( lid:String ):Object
		{
			var level:Object = this.getLevelProfileById( lid );
			if( !level ) return null;
			
			var ret:Object = {};
			for each( var monster:Object in level.monsters )
			{
				if( this.isMonster(monster.type) )
				{
					ret[monster.monster_id] = monster;
				}
			}
			return ret;
		}
		
		public function getMonstersByLevelId( lid:String ):Object 
		{
			var level:Object = this.getLevelProfileById( lid );
			if( !level ) return null;
			
			var ret:Object = {};
			for each( var monster:Object in level.monsters )
			{
				if( this.isMonster(monster.type) )
				{
					ret[monster.monster_id] = monster;
				}
			}
			return ret;
		}
		
		public function getBulletsByLevelId( lid:String ):Object
		{
			var level:Object = this.getLevelProfileById( lid );
			if( !level ) return null;
			
			var ret:Object = {};
			for each( var bullet:Object in level.monsters )
			{
				if( this.isBullet(bullet.type) )
				{
					ret[bullet.monster_id] = bullet;
				}
			}
			return ret;
		}
		
		public function getMaxMonsterId(lid:String): int
		{
			var enemies:Object = getLevelProfileById( lid ).monsters;
			
			var nextId:int = int(lid+"000");
			for each ( var m:Object in enemies )
			{
				nextId = Math.max( nextId, m.monster_id );
			}
			return nextId;
		}
		
		private function loadImage(onComplete:Function):void
		{
			var self:Data = this;
			var length:Number = 0, countor:Number = 0; 
			var callback:Function = function():void
			{
				var msg:String = self.validityCheckAndCleanUp();
				onComplete( msg + "\n【成功】载入"+length+"个图像资源\n");
			}
			
			var alldone:Function = function(face:String, done:Boolean):Function
			{
				return function(e:Event):void
				{
					if( done )
					{
						MapEditor.getInstance().addLog("加载"+face+"成功");
						var loader:Loader = (e.target as LoaderInfo).loader; 
						self.mEnemySkins[face] = Bitmap(loader.content).bitmapData;
					}
					if( ++countor >= length ) {
						MapEditor.getInstance().addLog("全部skin加载完成");
						callback();
					}
				}
			}
			var IMAGE:File = this.resolvePath( "skins" );
			if( IMAGE.exists && IMAGE.isDirectory )
			{
				var formats:Array = IMAGE.getDirectoryListing();
				for each( var file:File in formats )
				{
					var name:String = file.name.split(".")[0];
					var bytes:ByteArray = new ByteArray;
					
					var stream:FileStream = new FileStream();
					stream.open(file, FileMode.READ);
					stream.readBytes(bytes);
					stream.close();
					
					var loader:Loader = new Loader;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, alldone(name, true));
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, alldone(name, false));
					loader.loadBytes(bytes);
					
					length ++;
				}
			}
			
			if( length == 0 ) callback();
		}
		
		private function validityCheckAndCleanUp():String
		{
			var result:String = "";
			
			for each( var chapter:Object in this.mChapterProfiles )
			{
				for each( var level:Object in chapter.levels )
				{
					for each( var monster:Object in level.monsters )
					{
						if( this.isMonster( monster.type ) ||
							this.isBullet( monster.type ) ||
							this.isTrap( monster.type ) ) continue;
						
						this.eraseMonster( level.level_id, monster.monster_id );
						result += "【删除】未定义的敌人类型"+monster.monster_id+"("+monster.type+")";
					}
				}
			}
			
			// [TODO] add args checking for behaviors
			for( var lid:String in this.mLevelInstancesTable )
			{
				var profile:Object = this.getLevelProfileById( lid );
				if( !profile ) continue;
				
				var data:Array = this.mLevelInstancesTable[lid].data || [];
				var triggers:Object = this.mLevelInstancesTable[lid].trigger || {};
				var bhs:Object = this.mLevelInstancesTable[lid].behavior || {};
				
				var monsters:Object = profile.monsters || {};
				for each( var item:Object in monsters )
				{
					if( !("type" in item) ) 
						item.type = EditMonster.CUSTOM_BEHAVIOR_TYPES[0];
				}
				
				for( var iter:int = data.length-1; iter>=0; iter-- )
				{
					if( this.isMonster( data[iter].type ) && 
						!(data[iter].type in monsters) )
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
			var profile:Object = this.getLevelProfileById( lid );
			if( !(lid in this.mLevelInstancesTable ) || !profile  ) return "【失败】无相关地图数据存在";
			
			function adjust( name:String, itype:String, item:Object ):Array {
				
				var monsters:Object = Data.getInstance().getMonstersByLevelId( lid );
				var bullets:Object = Data.getInstance().getBulletsByLevelId( lid );
				var traps:Object = Data.getInstance().getTrapsByLevelId( lid );
				
				if( itype == "ccp" )
				{
					return [true, "@@cc.p("+item[0]+", "+item[1]+")@@"];
				} 
				else if ( itype == "ccsize" )
				{
					return [true, "@@cc.size("+item[0]+", "+item[1]+")@@"];
				} 
				else if ( itype == "path" )
				{
					var data:Array = [];
					for each ( var dot:Array in item )
					{
						data.push( "@@cc.p("+dot[0]+", "+dot[1]+")@@" );
					}
					return [true, data];
				}
				else if ( itype == "path2" )
				{
					data = [];
					for( var ii:int=1; ii<item.length; ii++ )
					{
						var dot1:Array = item[ii-1];
						var dot2:Array = item[ii];
						data.push( "@@cc.p("+String(item[ii][0]-item[ii-1][0])+", "+String(item[ii][1]-item[ii-1][1])+")@@" );
					}
					return [true, data];
				}
				else if ( itype == "bullet" )
				{
					if( !(item in bullets) )
						return [false, "【失败】"+name+"配置的子弹  "+item+"  是无效的"];
					else 
						return [true, null];
				}
				else if ( itype == "actor" )
				{
					if( !(item in monsters) )
						return [false, "【失败】"+name+"配置的怪物  "+item+"  是无效的"];
					else 
						return [true, null];
				}
				else if ( itype == "trap" )
				{
					if( !(item in traps) )
						return [false, "【失败】"+name+"配置的陷阱 "+item+" 是无效的"];
				}
				
				return [true, null];
			}
			
			var export:Object = new Object;
			var secList:Array = this.getLevelDataById( lid );
			// parse instances 
			export.sections = [];
			for each( var section:Object in secList )
			{
				var next:Object = {
					info : section.info,
					targets : section.targets,
					inst : []
				};
				
				var template:Array 	= Utils.deepCopy( Data.getInstance().dynamicArgs.Section ) as Array || [];
				for each( var info:Array in template )
				{
					if( !(info[ConfigPanel.kKEY] in next.info) )
						next.info[info[ConfigPanel.kKEY]] = info[ConfigPanel.kDEFAULT];
				}
				
				for each( var inst:Object in section.inst )
				{
					next.inst.push ( {
						type : inst.type,
						coord : "@@cc.p("+inst.x+","+inst.y+")@@",
						startDelay : inst.startDelay,
						delay : inst.delay,
						team : inst.team,
						id : inst.id
					} );
				}
				
				export.sections.push( next );
			}
			
			//
			export.config = this.getLevelConfigsById( lid );
			
			//
			var item:Object = null, bhTable:Object = {};
			export.profile = {};
			for( var index:String in profile.monsters )
			{
				item = Utils.deepCopy( profile.monsters[index] );
				export.profile[index] = item;
				export.profile[index].triggers = this.mLevelInstancesTable[lid].trigger[index] || [];
				
				if(EditMonster.isCustomBehaviorType(item.type))
				{
					if( !this.mLevelInstancesTable[lid].behavior.hasOwnProperty(index) ||
						this.mLevelInstancesTable[lid].behavior[index].length == 0 )
						return "【失败】自定义怪物"+index+"未被设置行为";
					this.mLevelInstancesTable[lid].behavior[index].forEach(
						function(item:*, ...args):void {
							bhTable[item] = true;
						}, null
					);
					export.profile[index].behaviors = this.mLevelInstancesTable[lid].behavior[index];
				}
					
				var kernal:String = null;
					
				if( this.isMonster( item.type ) )		kernal = "MonsterProfile"; 
				else if( this.isBullet( item.type ) ) 	kernal = "BulletProfile";
				else if( this.isTrap( item.type ) )		kernal = "TrapProfile";
				else return "【失败】未知的怪物类型"+item.type;
				
				if( kernal in Data.getInstance().dynamicArgs )
				{
					var subData:Object = Data.getInstance().dynamicArgs[kernal] || {};
					for each( var subItem:Object in subData )
					{
						var iKey:String 	= subItem[ConfigPanel.kKEY];
						var iType:String 	= subItem[ConfigPanel.kTYPE];
						if( !(iKey in export.profile[index]) )
							export.profile[index][iKey] = subItem[ConfigPanel.kDEFAULT];
						
						var adj:Array = adjust( 
							export.profile[index].monster_id, iType, export.profile[index][iKey] 
						);
						if( !adj[0] ) return adj[1];
						if( adj[1] ) export.profile[index][iKey] = adj[1];
						
					}
					
					var type:String = export.profile[index].type;
					if( type && type in Data.getInstance().dynamicArgs )
					{
						subData = Data.getInstance().dynamicArgs[type] || {};
						for each( subItem in subData )
						{
							iKey 	= subItem[ConfigPanel.kKEY];
							iType 	= subItem[ConfigPanel.kTYPE];
							if( !(iKey in export.profile[index]) )
								export.profile[index][iKey] = subItem[ConfigPanel.kDEFAULT];
							
							adj = adjust( 
								export.profile[index].monster_id, iType, export.profile[index][iKey] 
							);
							if( !adj[0] ) return adj[1];
							if( adj[1] ) export.profile[index][iKey] = adj[1];
						}
					}
				}
			}
			
			export.behavior = new Object;
			for( index in bhTable )
			{
				if( !this.mBehaviorSet.hasOwnProperty(index) ) {
					return "【失败】试图导出不存在的行为"+index;
				}
				var raw:String = Utils.genBTreeJS(Utils.cloneObjectData(this.mBehaviorSet[index]));
				export.behavior[index] = String("@@function(actor){var BT = namespace('Behavior','BT_Node','Gameplay');return " +
					""+raw+";}@@");
			} 
			
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
			var profile:Object = this.getLevelProfileById( lid );
			if( !profile ) 
				return null;
	
			if( !(lid in this.mLevelInstancesTable) )
			{
				return { 
					id : int(lid),
					stageId: int(profile.chapter_id),
					stage: profile.chapter_name,
					name: profile.level_name,
					path: "level/"+lid+".js", 
					enemies : [],
					roleExp: profile.player_exp,
					heroExp: profile.hero_exp
				};
			}
			
			var enemies:Object = {};
			var inst:Array = this.getLevelDataById( lid );
			for each( var section:Object in inst )
			{
				for each( var item:Object in section.inst )
				{
					var ip:Object = Data.getInstance().getEnemyProfileById(
						lid, item.type 
					);
					if( !ip || !this.isMonster( ip.type ) ) continue;
					
					if( !(item.type in enemies) ) {
						var m:Object = profile.monsters[item.type];
						enemies[item.type] = {
							type 	: int(item.type),
							count 	: 0,
							coins 	: m.coins || "",
							items 	: m.items || ""
						};
					}
					enemies[item.type].count ++;
				}
			}
			
			var array:Array = [];
			for each( var monster:* in enemies ) array.push( monster );
			
			var ret:Object = {
				id : int(lid),
				stageId: int(profile.chapter_id), 
				stage: profile.chapter_name,
				name: profile.level_name, path: "level/"+lid+".js", 
				enemies : array,
				roleExp: profile.player_exp,
				heroExp: profile.hero_exp
			};
			Utils.dumpObject( ret );
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