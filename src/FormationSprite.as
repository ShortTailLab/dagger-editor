package
{
	import flash.display.Shape;
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
				var dot:Shape = new Shape;
				dot.graphics.beginFill(0xff0000);
				dot.graphics.drawCircle(pos.x, pos.y, 8);
				dot.graphics.endFill();
				addChild(dot);
			}
		}
		
		public function trim(size:int):void
		{
			
			var scale:Number = Math.min(size/width, size/height);
			this.scaleX = this.scaleY = scale;
			
			//this.graphics.lineStyle(1);
			//this.graphics.drawRect(0, size, size, size);
		}
	}
}