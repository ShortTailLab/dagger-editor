package
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	
	public class StateBtn extends Sprite
	{
		var isOn:Boolean = false;
		
		public function StateBtn(name:String)
		{
			var padding:int = 5;
			
			var label:TextField = Utils.getLabel(name, padding, padding, 20);
			label.selectable = false;
			this.addChild(label);
			
			this.graphics.lineStyle(1);
			this.graphics.beginFill(0xffffff, 0);
			this.graphics.drawRect(0, 0, label.textWidth+padding*2, label.textHeight+padding*2);
			this.graphics.endFill();
			
			this.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:MouseEvent):void
		{
			isOn = !isOn;
			var color:uint = isOn ? 0xff00000: 0x000000;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
		}
	}
}