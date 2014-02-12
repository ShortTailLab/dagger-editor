package
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	
	import behaviorEdit.BType;

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
		
		static public function assert(val:Boolean):void
		{
			while(val)
			{}
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
					result += sourceData.data.execType+"(actor";
					//the format of data refer to execNode.exportData()
					var parms:Array = sourceData.data.parm as Array
					for(var i:int = 0; i < parms.length; i++)
					{
						if(parms[i].hasOwnProperty("value") && parms[i].value == "")
							return "";
						
						result += ",";
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
			var arr:Array = JSON.parse(str) as Array;
			return "@@cc.p("+arr[0]+","+arr[1]+")@@";
		}
		static public function arrayStr2ccsStr(str:String):String
		{
			var arr:Array = JSON.parse(str) as Array;
			return "@@cc.size("+arr[0]+","+arr[1]+")@@";
		}
		
		static public function deepCopy(obj:Object):Object
		{
			var objByte:ByteArray = new ByteArray;
			objByte.writeObject(obj);
			objByte.position = 0;
			return objByte.readObject();
		}
		
		static public function loadJsonFileToObject(path:String):Object
		{
			var file:File = File.desktopDirectory.resolvePath(path);
			var result:Object = null;
			if(file.exists)
			{
				var stream:FileStream = new FileStream;
				stream.open(file, FileMode.READ);
				result = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			}
			return result;
		}
		
	}
}