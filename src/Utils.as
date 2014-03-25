package 
{
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
	
	import mx.collections.ArrayList;
	import mx.containers.TitleWindow;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.ComboBox;
	import spark.events.IndexChangeEvent;
	
	import behaviorEdit.BType;
	
	import by.blooddy.crypto.MD5;

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
			var result:String = "";
			if(sourceData)
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
				
				if(sourceData.type == BType.BTYPE_EXEC)
				{
					result += sourceData.data.execType+"(";
					//the format of data refer to execNode.exportData()
					var parms:Array = sourceData.data.parm as Array
					for(var i:int = 0; i < parms.length; i++)
					{
						if(parms[i].hasOwnProperty("value") && parms[i].value == "")
							return "";
						
						if(i!=0) result += ",";
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
						else if(parms[i].type == "array_ccp" || parms[i].type == "array_ccp_curve")
						{
							var path:Array = parms[i].path as Array;
							result += "[";
							for(var j:int = 0; j < path.length; j++)
							{
								//path*2 to make it compatible to the old edition
								result += "cc.p("+(path[j].x*2)+","+(-path[j].y*2)+")";
								if(j < path.length-1)
									result += ","
							}
							result += "]";
						}
						else
							result += parms[i].value;
						
					}
					result += ")";
				}
					//except for exec node, others should have child nodes.
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
					{
						if(sourceData.data.times == "")
						{
							trace("genBtTree error: times is empty.");
							return "";
						}
						result += "BT.loop("+sourceData.data.times+",";
					}
					else if(sourceData.type == BType.BTYPE_COND)
					{
						if(sourceData.data.cond == "")
						{
							trace("genBtTree error: cond is empty.");
							return "";
						}
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
			}
			
			return result;
		}
		
		static public function comp2BNode(node1:Object, node2:Object):Boolean
		{
			return genBTreeJS(node1) == genBTreeJS(node2);
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
		
		static public function deepCopy(obj:Object):Object
		{
			var objByte:ByteArray = new ByteArray;
			objByte.writeObject(obj);
			objByte.position = 0;
			return objByte.readObject();
		}
		
		static public function write(src:String, path:String):Boolean
		{
			var file:File = new File(path);
			
			var stream:FileStream = new FileStream;
			stream.open(file, FileMode.WRITE);
			stream.writeUTFBytes( src );
			stream.close();
			return true;
		}
		
		static public function WriteRawFile( file:File, str:String ):void
		{
			var stream:FileStream = new FileStream;
			stream.open( file, FileMode.WRITE );
			stream.writeUTFBytes( str );
			stream.close();
		}
		
		static public function projectRoot():String
		{
			return File.desktopDirectory.resolvePath("editor").nativePath + "/";			
		}
		
		static public function LoadJSONToObject( file:File ):Object
		{
			var result:Object = null;
			if( file.exists ) 
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				result = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			return result;
		}
		
		static public function WriteObjectToJSON( file:File, item:Object):void
		{
			var stream:FileStream = new FileStream;
			stream.open( file, FileMode.WRITE );
			stream.writeUTFBytes( JSON.stringify(item, null, "\t") );
			stream.close();
		}
		
		static public function copyDirectoryTo(from:String, to:String):void
		{
			var f:File = File.desktopDirectory.resolvePath(from);
			var t:File = File.desktopDirectory.resolvePath(to);
			f.copyTo(t, true);
		}
		
		static public function parseObjToXML(obj:Object):XML
		{
			var xml:XML = <Root></Root>;
			for(var b:* in obj)
				xml.appendChild(new XML("<parm label='"+b+"'></parm>"));
			return xml;
		}
		
		static public function getObjectLength(obj:Object):uint
		{
			var length:uint = 0;
			for( var s:* in obj )
				length ++;
			return length;
		}
		
		static public function merge2Object(left:Object, right:Object):Object
		{
			var ret:Object = {};
			for( var key:String in left )
				ret[key] = left[key];
			for( var key:String in right )
				ret[key] = right[key];
			return ret;
		}
		
		static public function dumpObject( obj : *, level : int = 0 ) : void{
			var tabs : String = "";
			for ( var i : int = 0 ; i < level ; i++, tabs += "\t" );
			for ( var prop : String in obj ){
				trace( tabs + "[" + prop + "] -> " + obj[ prop ] );
				dumpObject( obj[ prop ], level + 1 );
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
		
		static public function makeManualPanel(msg:String, root:DisplayObject):TitleWindow
		{
			var mask:TitleWindow = new TitleWindow();
			with( mask ) {
				width = 300; height = 50;
				showCloseButton = false; title = msg;
			}
			
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
	}
}