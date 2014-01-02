package
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;

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
	}
}