package
{
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
		
		static public function makeGrid(source:Array, startPoint:Point, gridSize:int, cols:int, rows:int):void
		{
			for(var i:int = 0; i < source.length; i++)
			{
				source[i].x = startPoint.x + gridSize*(i%cols);
				source[i].y = startPoint.y + gridSize*int(i/rows);
			}
		}
	}
}