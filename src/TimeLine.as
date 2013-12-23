package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class TimeLine extends Sprite
	{
		private var marks:Vector.<TextField>;
		private var interval:int;
		private var timeInterval:int;
		private var heightPerUnit:Number;
		private var unitWidth:Number;
		private var gridXNum:int = 0;
		private var gridYNum:int = 0;
		
		public function TimeLine(sizePerUnit:int, timeInterval:int)
		{
			marks = new Vector.<TextField>;
			heightPerUnit = sizePerUnit;
			this.interval = sizePerUnit*timeInterval;
			this.timeInterval = timeInterval;
			
			var currHeight:int = 0;
			graphics.lineStyle(2);
			graphics.moveTo(0, currHeight);
			while(this.height < 1500)
			{
				var mark:TextField = new TextField();
				mark.defaultTextFormat = new TextFormat(null, 20);
				mark.width = 60;
				mark.x = -60;
				mark.y = -currHeight-20;
				
				marks.push(mark);
				addChild(mark);
				
				graphics.lineTo(-5, -currHeight);
				graphics.moveTo(0, -currHeight);
				currHeight+=interval;
				graphics.lineTo(0, -currHeight);
			}
			gridYNum = 1500/heightPerUnit;
		}
		
		public function setGridSize(num:int):void
		{
			gridXNum = num;
			unitWidth = 320/num;
			this.graphics.lineStyle(1, 0, 0.3);
			this.graphics.beginFill(0xffffff,0);
			this.graphics.drawRect(0, -gridYNum*heightPerUnit, 320, gridYNum*heightPerUnit);
			this.graphics.endFill();
			
			
			for(var i:int = 0; i <gridYNum; i++)
			{
				this.graphics.moveTo(0, -i*heightPerUnit);
				this.graphics.lineTo(320, -i*heightPerUnit);
			}
			for(var j:int = 0; j < num; j++)
			{
				this.graphics.moveTo(j*unitWidth, 0);
				this.graphics.lineTo(unitWidth*j, -(i-1)*heightPerUnit);
			}
			this.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		private function onClick(e:MouseEvent):void
		{
			var gX:int = e.localX/unitWidth;
			var gY:int = -e.localY/heightPerUnit;
			if(gX>=0 && gX<=gridXNum && gY>=0 && gY<=gridYNum)
			{
				var evt:TimeLineEvent = new TimeLineEvent("gridClick");
				evt.data.x = gX*unitWidth+unitWidth*0.5;
				evt.data.y = gY*heightPerUnit;
				this.dispatchEvent(evt);
			}
		}
		
		public function resize(h:int):void
		{
			var currHeight:int = 0;
			graphics.lineStyle(2);
			graphics.moveTo(0, currHeight);
			while(this.height < h)
			{
				var mark:TextField = new TextField();
				mark.text = "s";
				mark.defaultTextFormat = new TextFormat(null, 20);
				mark.x = -200;
				mark.y = -currHeight-mark.height;
				marks.push(mark);
				addChild(mark);
				
				graphics.lineTo(-5, -currHeight);
				graphics.moveTo(0, -currHeight);
				currHeight+=interval;
				graphics.lineTo(0, -currHeight);
			}
		}
		
		public function setCurrTime(time:int):void
		{
			var t:int = time;
			
			for each(var m:TextField in marks)
			{
				m.text = t+"s";
				t+=timeInterval;
			}
		}
	}
}