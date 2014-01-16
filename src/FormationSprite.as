package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	
	public class FormationSprite extends Sprite
	{
		public var fName:String;
		
		private var dots:Shape = null;
		private var frame:Shape = null;
		
		public function FormationSprite(name:String)
		{
			fName = name;
			frame = new Shape;
			addChild(frame);
			
			var posData:Array = Formation.getInstance().formations[name];
			dots = new Shape;
			this.addChild(dots);
			for each(var pos in posData)
			{
				dots.graphics.beginFill(0xff0000);
				dots.graphics.drawCircle(pos.x, pos.y, 8);
				dots.graphics.endFill();
			}
		}
		
		public function trim(size:int):void
		{
			this.graphics.beginFill(0xffffff, 0.1);
			this.graphics.drawRect(0, -size, size, size);
			this.graphics.endFill();
			
			frame.graphics.clear();
			frame.graphics.lineStyle(1);
			frame.graphics.drawRect(0, -size, size, size);
			frame.graphics.endFill();
			
			
			var scale:Number = Math.min(size/width, size/height);
			dots.scaleX = dots.scaleY = scale;
		}
		
		public function select(value:Boolean):void
		{
			var color:uint = value ? 0xff0000 : 0;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			frame.transform.colorTransform = transform;
		}
	}
}