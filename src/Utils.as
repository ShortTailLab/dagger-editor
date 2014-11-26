package 
{
	import BTEdit.BType;
	
	import by.blooddy.crypto.MD5;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import flashx.textLayout.debug.assert;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.collections.Sort;
	import mx.containers.TitleWindow;
	import mx.controls.Label;
	import mx.controls.Text;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	import mx.utils.ObjectUtil;
	
	import spark.components.Button;
	import spark.components.ComboBox;
	import spark.events.IndexChangeEvent;

	public class Utils
	{
		static public function getLabel(label:String, px:int = 0, py:int=0, size:int = 10):TextField
		{
			var t:TextField = new TextField;
			t.defaultTextFormat = new TextFormat(null, size);
			t.text = label;
			t.x = px;
			t.y = py;
			return t;
		}
		
		static public function makeGrid(startPoint:Point, gridSize:int, cols:int, index:int):Point
		{
			return new Point(startPoint.x + gridSize*(index%cols), startPoint.y + gridSize*int(index/cols));
		}
		
		static public function makeGrid2(startPoint:Point, w:int, h:int, cols:int, index:int):Point
		{
			return new Point(startPoint.x + w*(index%cols), startPoint.y + h*int(index/cols));
		}
		
		static public function connect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2, color:uint = 0):void
		{
			target.graphics.lineStyle(lineStyle, color);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p2.x, p2.y);
		}
		
		static public function verConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2, color:uint = 0):void
		{
			target.graphics.lineStyle(lineStyle, color);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p1.x, p2.y);
		}
		
		static public function horConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2, color:uint = 0):void
		{
			target.graphics.lineStyle(lineStyle, color);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p2.x, p1.y);
		}
		
		static public function squareConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2, color:uint = 0):void
		{
			target.graphics.lineStyle(lineStyle, color);
			target.graphics.moveTo(p1.x, p1.y);
			if(p1.x!=p2.x && p1.y!=p2.y)
				target.graphics.lineTo(p1.x, p2.y);
			target.graphics.lineTo(p2.x, p2.y);
		}
		
		static public function genBTreeJS(sourceData:Object):String
		{
			if(!sourceData)
				return "";
			
			// if this is a subtree reference, replace itself with the actual subtree
			if (sourceData.subTree)
				sourceData = Utils.deepCopy(Data.getInstance().behaviorSet[sourceData.subTree]);
			
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
			
			if(sourceData.type == BType.BTYPE_EXEC)
			{
				//the format of data refer to execNode.exportData()
				var parms:Array = sourceData.data.parm as Array;
				var paramStrs:Array = [];
				
				for(var i:int = 0; i < parms.length; i++)
				{
					if(parms[i].hasOwnProperty("value") && parms[i].value == "")
						return "";
					
					if(parms[i].type == "ccp")
					{
						var str:String = "cc.p("+parms[i].value+","+parms[++i].value+")";
						paramStrs.push(str);
					}
					else if(parms[i].type == "ccsize")
					{
						var str:String = "cc.size("+parms[i].value+","+parms[++i].value+")";
						paramStrs.push(str);
					}
					else if(parms[i].type == "node")
					{
						//the parms ask for a node while node array is empty.
						if(children.length == 0)
						{
							trace("genBtTree error:invalid node: a node parm is missing!");
							return "";
						}
						var str:String = childrenJS.shift();
						paramStrs.push(str);
					}
					else if(parms[i].type == "array_ccp" || parms[i].type == "array_ccp_curve")
					{
						var path:Array = parms[i].path as Array;
						var pointStrs:Array = path.map(function(p:*, i:int, arr:Array):String { return "cc.p("+p.x+","+p.y+")"; });
						var pathStr:String = "[" + pointStrs.join(",") + "]";
						paramStrs.push(pathStr);
					}
					else if(parms[i].type == "string")
					{
						var str:String = "";
						if(parms[i].value.indexOf("'") == 0)
							str = parms[i].value;
						else
							str = "'" + parms[i].value + "'";
						paramStrs.push(str);
					}
					else
					{
						var str:String = parms[i].value;
						paramStrs.push(str);
					}
				}
				var pStr:String = paramStrs.join(",");
				return printf("%s(%s)", sourceData.data.execType, pStr);
			}
			else if(children.length == 0)
			{
				//except for exec node, others should always have child nodes.
				trace("genBtTree error: children is empty.");
				return "";
			}
			else if(sourceData.type == BType.BTYPE_SEQ)
			{
				return printf("BT.seq(%s)", childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_PAR)
			{
				return printf("BT.par(%s)", childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_SEL)
			{
				return printf("BT.sel(%s)", childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_LOOP)
			{
				if(sourceData.times == "")
				{
					trace("genBtTree error: times is empty.");
					return "";
				}
				return printf("BT.sel(%s,%s)", sourceData.times, childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_COND)
			{
				if(sourceData.data.cond == "")
				{
					trace("genBtTree error: cond is empty.");
					return "";
				}
				return printf("BT.cond(%s,%s)", sourceData.data.cond, childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_ONCE) 
			{
				return printf("BT.once(%s)", childrenJS.join(","));
			}
			else if(sourceData.type == BType.BTYPE_EVERY)
			{
				if(sourceData.interval == "" || sourceData.skip == "") {
					trace("genBtTree error: interval/skip is empty.");
					return "";
				}
				return printf("BT.every(%f,%s,%d)", sourceData.interval, childrenJS.join(","), sourceData.skip);
			}
			else if (sourceData.type == BType.BTYPE_RANDOM) 
			{
				var weightStr:String = sourceData.weights.join(",");
				var childrenStr:String = childrenJS.join(",");
				return printf("BT.randomSelect([%s],[%s])", weightStr,  childrenStr);
			}
			else
				return "";
		}
		
		static public function arrayStr2ccpStr(str:String):String
		{
			var arr:Array = [0, 0];
			if( str != "" ) 
				arr = JSON.parse(str) as Array;
			return "@@cc.p("+arr[0]+","+arr[1]+")@@";
		}
		static public function arrayStr2ccsStr(str:String):String
		{
			var arr:Array = [0, 0];
			if( str != "" ) 
				arr = JSON.parse(str) as Array;
			return "@@cc.size("+arr[0]+","+arr[1]+")@@";
		}

		static public function WriteRawFile( file:File, str:String ):void
		{
			var stream:FileStream = new FileStream;
			stream.open( file, FileMode.WRITE );
			stream.writeUTFBytes( str );
			stream.close();
			
			trace("raw file: \n", str);
		}
		
		static public function projectRoot():String
		{
			return File.desktopDirectory.resolvePath("editor").nativePath + "/";			
		}
		
		//--------------------------------
		// Json helpers
		//--------------------------------
		
		static public function LoadJSONToObject( file:File ):Object
		{
			var result:Object = null;
			if( file.exists ) 
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				//trace( file.url );
				//trace( stream.bytesAvailable ) ;
				var bytes:String = stream.readUTFBytes(stream.bytesAvailable);
				result = JSON.parse(bytes);
				stream.close();
			}
			return result;
		}
		
		static public function WriteObjectToJSON( file:File, item:Object):void
		{
			var stream:FileStream = new FileStream;
			stream.open( file, FileMode.WRITE );
			//stream.writeUTFBytes( JSON.stringify(item, null, "\t") );
			stream.writeUTFBytes( toJsonSorted(item) );
			stream.close();
		}
		
		static public function toJsonSorted(item:Object):String
		{
			var str:String = "";
			str += "{\n";
			str += toJsonSortedRev(item, 1);
			str += "}\n";
			
			return str;
		}
		
		static private function toJsonSortedRev(item:Object, level:int):String 
		{
			var keys:Array = getKeys(item);
			keys.sort();
			
			var str:String = "";
			
			var space:String = "";
			for(var i:int=0; i<level; i++)
				space += "    ";
			
			var isArray:Boolean = item is Array;

			for each(var key:String in keys)
			{
				var val:* = item[key];
				
				// last element does not have ending comma
				var comma:String = (key == keys[keys.length-1]) ? "" : ",";

				var keyStr:String = isArray ? "" : printf("\"%s\": ", key);
				
				if(val is String){
					str += printf("%s%s\"%s\"%s\n", space, keyStr, val, comma);
				}
				else if(val is Boolean) {
					str += printf("%s%s%s%s\n", space, keyStr, val?"true":"false", comma);
				}
				else if(val is Number){
					str += printf("%s%s%s%s\n", space, keyStr, val, comma);
				}
				else if(val is Array) {
					str += printf("%s%s[\n", space, keyStr);
					str += toJsonSortedRev(val, level+1);
					str += printf("%s]%s\n", space, comma);
				}
				else if(val is Object) {
					str += printf("%s%s{\n", space, keyStr);
					str += toJsonSortedRev(val, level+1);
					str += printf("%s}%s\n", space, comma);
				}
				else if(val == null)
				{
					str += printf("%s%s%s%s\n", space, keyStr, "null", comma);
				}
				else {
					throw "Unkown type";
				}
			}
			
			// escape all back slashes
			var pattern:RegExp = /\\/g;
			str = str.replace(pattern, "\\\\");
			
			return str;
		}
		
		static public function parseObjToXML(obj:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b:* in obj)
				xml.appendChild(new XML("<parm label='"+b+"'></parm>"));
			return xml;
		}

		static public function dumpObject( obj : *, level : int = 0 ) : void{
			trace(" ------------------------ " );
			Utils.dumpObject2(obj, level);
			trace(" ^^^^^^^^^^^^^^^^^^^^^^^^ " );
		}
		
		static protected function dumpObject2( obj:*, level:int = 0 ):void
		{
			var tabs : String = "";
			for ( var i : int = 0 ; i < level ; i++, tabs += "\t" );
			for ( var prop : String in obj ){
				trace( tabs + "[" + prop + "] -> " + obj[ prop ] );
				dumpObject2( obj[ prop ], level + 1 );
			}
		}
		
		static public function getMD5Sum(file:File):String {
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			var bytesArray:ByteArray = new ByteArray();
			fileStream.readBytes(bytesArray, 0, fileStream.bytesAvailable);
			fileStream.close();
			return MD5.hashBytes(bytesArray);
		}
		
		// ----------------------------------------------
		static public function makeComboboxPanel(
			onComplete:Function, root:DisplayObject, data:Array, t:String="请输入"
		):void {
			var panel:TitleWindow = new TitleWindow();
			with( panel ) {
				title = t; width = 170; height = 100;
			}
			
			var al:ArrayList = new ArrayList(data);
			var cb:ComboBox = new ComboBox();
			with( cb ) {
				x = 10; y = 10; width = 150;
				dataProvider = al;	
				requireSelection = true;
			}
			
			var confirmButton:Button = new Button;
			with( confirmButton ) {
				label = "确定"; x = 10; y = 40;  
			}
			confirmButton.addEventListener( MouseEvent.CLICK, 
				function( e:MouseEvent ) :void {
					onComplete(cb.selectedIndex);
					PopUpManager.removePopUp(panel);
				}
			);
			
			panel.addElement( cb );
			panel.addElement( confirmButton );
			
			panel.addEventListener(CloseEvent.CLOSE, function():void {
				onComplete(null);
				PopUpManager.removePopUp(panel);
			});
			
			PopUpManager.addPopUp( panel, root, true );
			PopUpManager.centerPopUp( panel );
		}
		
		static public function makeRenamePanel(onComplete:Function, root:DisplayObject, t:String="请输入"):void
		{
			var panel:TitleWindow = new TitleWindow();
			with( panel ) {
				title = t; width = 170; height = 100;
			}
			
			var inputField:TextInput = new TextInput;
			with( inputField ) { 
				x = 10; y = 10; height 30; width = 150; 
			}
			
			var confirmButton:Button = new Button;
			with( confirmButton ) {
				label = "确定"; x = 10; y = 40;  
			}
			confirmButton.addEventListener( MouseEvent.CLICK, 
				function( e:MouseEvent ) :void {
					onComplete(inputField.text);
					PopUpManager.removePopUp(panel);
				}
			);
			
			panel.addElement(inputField);
			panel.addElement(confirmButton);
			
			panel.addEventListener(CloseEvent.CLOSE, function():void {
				PopUpManager.removePopUp(panel);
			});
			
			PopUpManager.addPopUp( panel, root, true );
			PopUpManager.centerPopUp( panel );
		}
		
		static public function makeManualPanel(titleMsg:String, root:DisplayObject):TitleWindow
		{
			var mask:TitleWindow = new TitleWindow();
			with( mask ) {
				width = 600; 
				height = 500;
				showCloseButton = false; 
				title = titleMsg;
			}
			
			var text:Text = new Text;
			mask.addElement(text);
			
			PopUpManager.addPopUp( mask, root, true );
			PopUpManager.centerPopUp( mask );
			return mask;
		}
		
		static public function releaseManualPanel( p:TitleWindow ):void
		{
			PopUpManager.removePopUp( p );
		}
		
		static public function getTimeFormat( s:int ):String
		{
			var m:int = 0;
			while( s > 60 ) {
				m++; s-= 60;
			}
			
			if( m>0 ) return m+"m"+s+"s";
			return s+"s";
		}
		
		
		static public function deepCopy(obj:Object):Object
		{
			var objByte:ByteArray = new ByteArray;
			objByte.writeObject(obj);
			objByte.position = 0;
			return objByte.readObject();
		}
		
		static public function cloneObjectData(data:Object):Object {
			return JSON.parse(JSON.stringify(data));
		}
		
		static public function getLastInt(str:String):int {
			var r:int;
			for (var i:int = str.length-1; i >= 0; i--) {
				if (str.charAt(i) < "0" || str.charAt(i) > "9") break;
			}
			r = int(str.substr(i+1));
			return r;
		}
		
		static public function getKeys(o:Object) : Array {
			var array:Array = new Array;
			for(var key:String in o)
				array.push(key);
			return array;
		}
		
		static public function getKeysAsSortedData(o:Object) : ArrayCollection {
			var array:Array = getKeys(o);
			var collection:ArrayCollection = new ArrayCollection(array);
			collection.sort = new Sort;
			collection.refresh();
			return collection;			
		}
		
		static public function clamp(val:Number, min:Number, max:Number): Number
		{
			return Math.max(min, Math.min(val, max));
		}
		
		
		
		//-----------------------------------
		// Object merge helpers
		//-----------------------------------
		
		// merge all keys and return them as a new object
		static public function unionMerge(left:Object, right:Object):Object
		{
			var ret:Object = {};
			for( var key:String in left )
				ret[key] = left[key];
			for( var key:String in right )
				ret[key] = right[key];
			return ret;
		}
		
		// merge all keys in src object
		static public function fatMerge(dst:Object, src:Object, ignore:Array = null): Object
		{			
			var keys:Array = getKeys(src);
			
			if(ignore)
			{
				keys = keys.filter(function(k:String, index:int, array:Array):Boolean { 
					return ignore.indexOf(k) == -1; 
				});
			}
			
			for each(var key:String in keys)
			{
				dst[key] = src[key];
			}
			return dst;
		}
		
		// only merge keys that exist in dst object
		static public function thinMerge(dst:Object, src:Object, ignore:Array = null): Object
		{
			var keys:Array = getKeys(dst);
			
			if(ignore)
			{
				keys = keys.filter(function(k:String, index:int, array:Array):Boolean { 
					return ignore.indexOf(k) == -1; 
				});
			}
			
			for each(var key:String in keys)
			{
				if(src[key])
					dst[key] = src[key];
			}
			return dst;
		}
		
		// only merge keys that do not exist in dst object
		static public function xorMerge(dst:Object, src:Object, ignore:Array = null): Object
		{
			var keys:Array = getKeys(src);
			
			if(ignore)
			{
				keys = keys.filter(function(k:String, index:int, array:Array):Boolean { 
					return ignore.indexOf(k) == -1; 
				});
			}
			
			for each (var key:String in keys) 
			{
				if(!dst.hasOwnProperty(key))
					dst[key] = src[key];
			}
			return dst;
		}
	}
}