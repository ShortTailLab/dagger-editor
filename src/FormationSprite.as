package
{
	import flash.display.Sprite;
	
	public class FormationSprite extends Sprite
	{
		public var fName:String;
		
		public function FormationSprite(name:String)
		{
			fName = name;
			var posData:Array = Formation.getInstance().formations[name];
			graphics.lineStyle(1);
			for each(var pos in posData)
			{
				graphics.beginFill(0xffffff);
				graphics.drawCircle(pos.x, pos.y, 8);
				graphics.endFill();
			}
		}
		
		public function trim(size:int):void
		{
			var scale:Number = Math.min(size/width, size/height);
			this.scaleX = this.scaleY = scale;
		}
	}
}