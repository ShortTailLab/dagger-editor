package editEntity
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;

	public class TriggerSprite extends EditBase
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static var TRIGGER_TYPE:String = "AreaTrigger";
		private var rect:Rectangle = null;
		private var triggerPoint:Sprite = null;
		
		public function TriggerSprite()
		{
			this.type = TRIGGER_TYPE;
			//左上角为原点
			rect = new Rectangle(-50, -100, 100, 100);
			
			addDot(-50, -100);
			addDot(50, -100);
			addDot(50, 0);
			addDot(-50, 0);
			
			triggerPoint = new Sprite;
			triggerPoint.graphics.beginFill(0);
			triggerPoint.graphics.drawCircle(0, 0, 8);
			triggerPoint.graphics.endFill();
			this.addChild(triggerPoint);
			
			render();
		}
		
		public function enable(value:Boolean):void
		{
			for(var i:int = 0; i < 4; i++)
			{
				if(value)
				{
					dots[i].addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
					dots[i].addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				}
				else
				{
					dots[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
					dots[i].removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				}
			}
		}
		
		override public function trim(size:Number):void
		{
			var scale:Number = size/this.width;
			this.scaleX = this.scaleY = scale;
		}
		
		override public function select(value:Boolean):void
		{
			isSelected = value;
			var color:uint = value ? 0xff0000 : 0;
			var transform:ColorTransform = new ColorTransform;
			transform.color = color;
			this.transform.colorTransform = transform;
		}
		
		override public function initFromData(data:Object):void
		{
			this.x = data.x/2;
			this.y = -data.y/2;
			if(data.hasOwnProperty("triggerTime"))
				this.triggerTime = data.triggerTime;
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.type = type;
			obj.x = x*2;
			obj.y = Number(-y*2);
			if(this.triggerTime > 0)
				obj.triggerTime = this.triggerTime;
			return obj;
		}
		
		private function addDot(px:int, py:int):void
		{
			var dot:Sprite = new Sprite;
			dot.graphics.beginFill(0x000000);
			dot.graphics.drawCircle(0, 0, 8);
			dot.graphics.endFill();
			dots.push(dot);
			dot.x = px;
			dot.y = py;
			this.addChild(dot);
		}
		
		private function render():void
		{	
			this.graphics.clear();
			this.graphics.lineStyle(1);
			this.graphics.beginFill(0x000000, 0.5);
			this.graphics.moveTo(rect.x, rect.y);
			this.graphics.lineTo(rect.right, rect.y);
			this.graphics.lineTo(rect.right, rect.bottom);
			this.graphics.lineTo(rect.x, rect.bottom);
			this.graphics.lineTo(rect.x, rect.y);
			this.graphics.endFill();
			
		}
		
		private function updateRect():void
		{
			if(currId == -1)
				return;
			var currDot:Sprite = dots[currId];
			var nailDot:Sprite = dots[(currId+2)%4];
			var currRight:Sprite = dots[(currId+1)%4];
			var currLeft:Sprite = dots[(currId+3)%4];
			rect.x = Math.min(nailDot.x, currDot.x);
			rect.y = Math.min(nailDot.y, currDot.y);
			rect.width = Math.abs(nailDot.x - currDot.x);
			rect.height = Math.abs(nailDot.y - currDot.y);
			
			if(currRight.x == nailDot.x)
			{
				currRight.y = currDot.y;
				currLeft.x = currDot.x;
			}
			else
			{
				currRight.x = currDot.x;
				currLeft.y = currDot.y;
			}
			
			triggerPoint.x = rect.x+rect.width*0.5;
			triggerPoint.y = rect.y+rect.height*0.5;
		}
		
		private function onEnterFrame(e:Event):void
		{
			updateRect();
			render();
		}
		
		private var currId:int = -1;
		private function onMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			var dot:Sprite = e.currentTarget as Sprite;
			for(var i:int = 0; i < 4; i++)
				if(dots[i] == dot)
				{
					currId = i;
					break;
				}
			dot.startDrag();
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			e.stopPropagation();
			var dot:Sprite = e.currentTarget as Sprite;
			dot.stopDrag();
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			currId = -1;
		}
	}
}