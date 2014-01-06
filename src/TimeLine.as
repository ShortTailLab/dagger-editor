package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class TimeLine extends Sprite
	{
		private var marks:Vector.<TextField>;
		private var interval:int;
		private var timeInterval:int;
		private var heightPerUnit:Number;
		private var unitWidth:Number;
		private var gridCols:int = 0;
		private var gridRows:int = 0;
		
		public function TimeLine(sizePerUnit:int, timeInterval:int, gridColsNum:int)
		{
			marks = new Vector.<TextField>;
			heightPerUnit = sizePerUnit;
			this.interval = sizePerUnit*timeInterval;
			this.timeInterval = timeInterval;
			this.gridCols = gridColsNum;
		}
		
		private function onClick(e:MouseEvent):void
		{
			if(e.target == this)
			{
				var gX:int = e.localX/unitWidth;
				var gY:int = -e.localY/heightPerUnit;
				if(gX>=0 && gX<=gridCols && gY>=0 && gY<=gridRows)
				{
					var evt:TimeLineEvent = new TimeLineEvent("gridClick");
					evt.data.x = gX*unitWidth+unitWidth*0.5;
					evt.data.y = gY*heightPerUnit;
					this.dispatchEvent(evt);
				}
			}
		}
		
		public function getGridPos(x:int, y:int):Point
		{
			var gX:int = x/unitWidth;
			var gY:int = -y/heightPerUnit;
			if(gX>=0 && gX<=gridCols && gY>=0 && gY<=gridRows)
				return new Point(gX*unitWidth+unitWidth*0.5, gY*heightPerUnit);
			return null;
		}
		
		public function resize(h:int):void
		{
			graphics.clear();
			while(marks.length > 0)
			{
				removeChild(marks[0]);
				marks.shift();
			}
				
			
			var currHeight:int = 0;
			graphics.lineStyle(2);
			graphics.moveTo(0, currHeight);
			
			while(currHeight < h)
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
				
			gridRows = currHeight/heightPerUnit;
			setGridCols(gridCols);
		}
		
		public function setGridCols(num:int):void
		{
			gridCols = num;
			unitWidth = 320/num;
			this.graphics.lineStyle(1, 0, 0.3);
			this.graphics.beginFill(0xffffff,0);
			this.graphics.drawRect(0, -gridRows*heightPerUnit, 320, gridRows*heightPerUnit);
			this.graphics.endFill();
			
			
			for(var i:int = 0; i <gridRows; i++)
			{
				this.graphics.moveTo(0, -i*heightPerUnit);
				this.graphics.lineTo(320, -i*heightPerUnit);
			}
			for(var j:int = 0; j < num; j++)
			{
				this.graphics.moveTo(j*unitWidth, 0);
				this.graphics.lineTo(unitWidth*j, -i*heightPerUnit);
			}
			this.addEventListener(MouseEvent.MOUSE_UP, onClick);
		}
		
		public function setCurrTime(time:int):void
		{
			var t:int = time;
			
			for each(var m:TextField in marks)
			{
				m.text = String(t);
				t+=timeInterval;
			}
		}
	}
}