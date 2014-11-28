package misc
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import spark.components.BorderContainer;
	import spark.components.Label;
	
	public class SceneGrid extends Sprite
	{
		public function SceneGrid(width:Number, height:Number, centerAsOrigin:Boolean = true)
		{
			super();
			
			var Width:int = width;
			var Height:int = height;
						
			// border line
			this.graphics.lineStyle(1, 0xAAAAAA);
			this.graphics.moveTo(0,0);
			this.graphics.lineTo(Width, 0);;
			this.graphics.moveTo(0,0);
			this.graphics.lineTo(0, -Height);
			
			// width marks
			for (var i:int = 0; i <= Width; i+=120) {
				this.graphics.moveTo(i,0);
				this.graphics.lineTo(i, 20);
				
				var label:TextField = new TextField();
				label.scaleX = label.scaleY = 2;
				label.mouseEnabled = false;
				
				if(centerAsOrigin)
				{
					label.text = (i-Width*0.5).toString();
					label.x = i-(i==Width*0.5?0:10);
					label.y = 15;
				}
				else
				{
					label.text = i.toString();
					label.x = i-(i==Width*0.5?0:10);
					label.y = 15;
				}
				this.addChild(label);
			}
			
			// height marks
			for (i = 0; i <= Height; i+=80) {
				this.graphics.moveTo(0,-i);
				this.graphics.lineTo(-20, -i);
				
				var label:TextField = new TextField();
				label.scaleX = label.scaleY = 2;
				label.mouseEnabled = false;
				
				if(centerAsOrigin)
				{
					label.text = (i-Height*0.5).toString();
					label.x = -60;
					label.y = -i-15;
				}
				else
				{
					label.text = i.toString();
					label.x = -60;
					label.y = -i-15;
				}
				this.addChild(label);
			}
			
			// bg rect
			this.graphics.beginFill(0xEEEEEE);
			this.graphics.drawRect(0, 0, Width, -Height);
			this.graphics.endFill();
			this.graphics.moveTo(Width*0.5-20, -Height*0.5);
			this.graphics.lineTo(Width*0.5+20, -Height*0.5);
			this.graphics.moveTo(Width*0.5, -(Height*0.5-20));
			this.graphics.lineTo(Width*0.5, -(Height*0.5+20));
		}
	}
}