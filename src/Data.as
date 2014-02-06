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
	
	import behaviorEdit.BType;
	
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
		public var enemyBTData:Object = null;
		public var behaviors:Object = null;
		public var displayData:Array = null;
		public var levelXML:XML = null;
		public var behaviorsXML:XML = null;
		public var enemySkinDic:Dictionary;
		public var currSelectedLevel:int = 0;
		public var behaviorBaseNode:Object = null;
		
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
			
			//this record the behaviors' name of each enemy
			var file:File = File.desktopDirectory.resolvePath("editor/enemyBehaviorsData.json");
			enemyBTData = null;
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				enemyBTData = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			//you can see the struct of enemyBTData here.
			if(!enemyBTData)
			{
				enemyBTData = new Object;
				for(var item in enemyData)
				{
					enemyBTData[item] = new Array;
				}
			}
			
			//this records all behaviors.
			file = File.desktopDirectory.resolvePath("editor/behaviors.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				behaviors = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
				//check the null behavior
				/*for(var b in behaviors)
					if(!behaviors[b])
						delete behaviors[b];*/
			}
			else
				behaviors = new Object;
			
			
			file = File.desktopDirectory.resolvePath("editor/bt_node_format.json");
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				this.behaviorBaseNode = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			else
				Alert.show("bt_node_format.json丢失，打开怪物行为时候可能会出错!");
			
			behaviorsXML = this.parseBehaviorXML(behaviors);
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
			var file:File = File.desktopDirectory.resolvePath("editor/behaviors.json");
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes(JSON.stringify(behaviors));
			stream.close();
		}
		
		public function genBTreeJS(sourceData:Object):String
		{
			var children:Array = sourceData.children as Array;
			var childrenJS:Array = new Array;
			for each(var childData:Object in children)
			{
				var js:String = genBTreeJS(childData);
				//if any child return "", the whole tree is invalid and should be ""
				if(js == "")
					return "";
				childrenJS.push(js);
			}
			
			var result:String = "";
			if(sourceData.type == BType.BTYPE_EXEC)
			{
				result += sourceData.data.execType+"(";
				var parms:Array = sourceData.data.parm as Array
				for(var i:int = 0; i < parms.length; i++)
				{
					if(parms[i].type == "ccp")
					{
						result += "cc.p("+parms[i].value+","+parms[++i].value+")";
					}
					else if(parms[i].type == "ccsize")
					{
						result += "cc.size("+parms[i].value+","+parms[++i].value+")";
					}
					else if(parms[i].type == "node")
					{
						//the parms ask for a node while node array is empty.
						if(children.length == 0)
						{
							trace("genBtTree error:invalid node: a node parm is missing!");
							return "";
						}
						result += childrenJS.shift();
					}
					else
						result += parms[i].value;
					
					if(i < parms.length-1)
						result += ",";
				}
				result += ")";
			}
			else if(children.length == 0)
			{
				trace("genBtTree error: children is empty.");
				return "";
			}
			else
			{
				if(sourceData.type == BType.BTYPE_SEQ)
					result += "BT.seq(";
				else if(sourceData.type == BType.BTYPE_PAR)
					result += "BT.par(";
				else if(sourceData.type == BType.BTYPE_SEL)
					result += "BT.sel(";
				else if(sourceData.type == BType.BTYPE_LOOP)
					result += "BT.loop("+sourceData.data.times+",";
				else if(sourceData.type == BType.BTYPE_COND)
				{
					result += "BT.cond("+sourceData.data.cond+",";
				}
				else
					return "";
				
				while(childrenJS.length > 0)
				{
					result += childrenJS.shift();
					if(childrenJS.length > 0)
						result += ",";
				}
				result += ")";
			}
			return result;
		}
		
		
		public function exportJS():void
		{
			/*for(var type in enemyEditData)
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
			}*/
			var source:Array = displayData[currSelectedLevel].data;
			
			var exportData:Object = new Object;
			exportData.actor = new Object;
			exportData.trap = new Object;
			exportData.objects = new Object;
			exportData.trigger = new Array;
			exportData.bullet = new Object;
			exportData.luck = new Object;
			exportData.behavior = new Object;
			
			for(var bName in behaviors)
			{
				var js:String = genBTreeJS(behaviors[bName]);
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
				var data:Object = enemyData[name];
				
				if(enemyBTData.hasOwnProperty(name))
					data.behaviors = enemyBTData[name];
				else
					data.behaviors = new Array;
				
				if(data.face >= 10000 && data.face < 20000)
				{
					exportData.bullet[name] = data;
				}
				else
				{
					/*data.actions = new Array;
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
					}*/
					
					/*if(behaviorData.hasOwnProperty(name) && behaviorData[name])
					{
						data.behaviors = "@@@function(){return "+getBTreeJS(behaviorData[name], false)+";}@@@";
					}
					else
						data.behaviors = null;*/
					
					if(!data.hasOwnProperty("attack"))
						data.attack = 1;
					if(!data.hasOwnProperty("health"))
						data.health = 1;
					if(!data.hasOwnProperty("defense"))
						data.defense = 1;
					exportData.actor[name] = data;
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
			var reg1:RegExp = /"@@/g;
			var reg2:RegExp = /@@"/g;
			var result:String = "";
			result = js.replace(reg1, "");
			result = result.replace(reg2, "");
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
			var levels:XML = <Root></Root>
			for each(var item in data)
				levels.appendChild(new XML("<level label='"+item.levelName+"'></level>"));
			return levels;
		}
		
		public function parseBehaviorXML(data:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b in data)
				xml.appendChild(new XML("<behavior label='"+b+"'></behavior>"));
			return xml;
		}
		
		public function addBehaviors(name:String, data:Object):void
		{
			if(!behaviors.hasOwnProperty(name))
			{
				behaviors[name] = data;
				behaviorsXML.appendChild(new XML("<behavior label='"+name+"'></behavior>"));
				this.saveBehaviorData();
			}
			else
				trace("addBehaviors error: behavior exists!");
		}
		
		public function updateBehavior(name:String, data:Object):Boolean
		{
			if(behaviors.hasOwnProperty(name))
			{
				behaviors[name] = data;
				this.saveBehaviorData();
				return true
			}
			else
			{
				trace("update behavior: behavior"+name+" is not exsit!");
				return false;
			}
		}
		
		public function renameBehavior(prevName:String, currName:String):void
		{
			if(behaviors.hasOwnProperty(currName))
			{
				trace("renamebehavior:currname is invalid!")
				return;
			}
			this.addBehaviors(currName, behaviors[prevName]);
			this.deleteBehaviors(prevName);
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