package
{
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.core.UIComponent;

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
		
		static public function connect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2):void
		{
			target.graphics.lineStyle(lineStyle);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p2.x, p2.y);
		}
		
		static public function verConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2):void
		{
			target.graphics.lineStyle(lineStyle);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p1.x, p2.y);
		}
		
		static public function horConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2):void
		{
			target.graphics.lineStyle(lineStyle);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p2.x, p1.y);
		}
		
		static public function squareConnect(target:UIComponent, p1:Point, p2:Point, lineStyle:int = 2):void
		{
			target.graphics.lineStyle(lineStyle);
			target.graphics.moveTo(p1.x, p1.y);
			target.graphics.lineTo(p1.x, p2.y);
			target.graphics.lineTo(p2.x, p2.y);
		}
		
		
	}
}