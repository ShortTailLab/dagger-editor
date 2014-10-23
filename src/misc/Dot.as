package misc
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	class Dot extends Sprite
	{
		private var label:TextField;
		
		public function Dot(color:uint)
		{
			graphics.beginFill(color);
			graphics.drawCircle(0, 0, 10);
			graphics.endFill();
			
			label = new TextField;
			label.defaultTextFormat = new TextFormat(null, 20);
			label.selectable = false;
			label.width = label.height = 20;
			
			addChild(label);
		}
		
		public function setNum(num:int):void
		{
			label.text = String(num);
			label.x = -label.textWidth*0.5;
			label.y = -label.textHeight*0.5;
		}
	}
}