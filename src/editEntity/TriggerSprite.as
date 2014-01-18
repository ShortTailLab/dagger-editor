package editEntity
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	public class TriggerSprite extends EditBase
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static var TRIGGER_TYPE:String = "AreaTrigger";
		private var rect:Rectangle = null;
		public var beginTriDot:Sprite = null;
		public var triggerMatIds:Array = null;
		public var dotsDic:Dictionary = null;
		private var view:EditView;
		private var triggerLayer:Sprite;
		
		private var isActive:Boolean = false;
		private var editable:Boolean = false;
		
		public function TriggerSprite()
		{
			this.type = TRIGGER_TYPE;
			//左上角为原点
			rect = new Rectangle(-50, -100, 100, 100);
			triggerMatIds = new Array;
			dotsDic = new Dictionary;
			initRectDots();
		}
		
		public function active(_view:EditView):void
		{
			isActive = true;
			view = _view;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function initTriggerMats():void
		{
			for each(var id:String in triggerMatIds)
			{
				var dot:Sprite = createDot();
				dot.addEventListener(MouseEvent.MOUSE_DOWN, onTirggerDotMouseDown);
				triggerLayer.addChild(dot);
				dotsDic[id] = dot;
			}
		}
		
		private function initRectDots():void
		{
			while(dots.length > 0)
				this.removeChild(dots.pop() as DisplayObject);
			addDot(rect.x, rect.y);
			addDot(rect.right, rect.y);
			addDot(rect.right, rect.bottom);
			addDot(rect.x, rect.bottom);
			updateRect();
		}
		
		public function addATrigger(id:String):void
		{
			if(dotsDic.hasOwnProperty(id))
				return;
			var dot:Sprite = createDot();
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onTirggerDotMouseDown);
			triggerLayer.addChild(dot);
			dotsDic[id] = dot;
			triggerMatIds.push(id);
		}
		
		private function onTirggerDotMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			for(var id in dotsDic)
				if(dotsDic[id] == e.currentTarget)
				{
					controlDot = dotsDic[id];
					control(controlDot);
					removeATrigger(id);
					return;
				}
		}
		
		public function removeATrigger(id:String):void
		{
			for(var i:int = 0; i < triggerMatIds.length; i++)
				if(triggerMatIds[i] == id)
				{
					triggerMatIds.splice(i, 1);
					delete dotsDic[id];
					break;
				}
		}
		
		private function createDot():Sprite
		{
			var dot:Sprite = new Sprite;
			dot.graphics.beginFill(0);
			dot.graphics.drawCircle(0, 0, 8);
			dot.graphics.endFill();
			return dot;
		}
		
		private var controlDot:Sprite = null;
		private function onTriggerMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			var pos:Point = this.globalToLocal(beginTriDot.localToGlobal(new Point(e.localX, e.localY)));
			controlDot = createDot();
			controlDot.x = pos.x;
			controlDot.y = pos.y;
			triggerLayer.addChild(controlDot);
			control(controlDot);
		}
		
		private function control(target:Sprite):void
		{
			target.addEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			target.startDrag();
		}
		
		private function onControlMouseUp(e:MouseEvent):void
		{
			controlDot.removeEventListener(MouseEvent.MOUSE_UP, onControlMouseUp);
			controlDot.stopDrag();
			var globalPos:Point = triggerLayer.localToGlobal(new Point(controlDot.x, controlDot.y));
			var id:String = findId(globalPos);
			if(id != "")
				addATrigger(id);
			triggerLayer.removeChild(controlDot);
			controlDot = null;
		}
		
		private function findId(globalPos:Point):String
		{
			var mats:Array = view.matsControl.getMatByPoint(globalPos);
			for each(var m:EditBase in mats)
				if(m.id != this.id)
					return m.id;
			return "";
		}
		
		private function onAdded(e:Event):void
		{
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		}
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			
		}
		private function onKeyUp(e:KeyboardEvent):void
		{
			
		}
		
		public function enableRectAdjust(value:Boolean):void
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
		public function enableEdit(value:Boolean):void
		{
			editable = value;
			if(value)
			{
				triggerLayer = new Sprite;
				this.addChild(triggerLayer);
				beginTriDot = createDot();
				triggerLayer.addChild(beginTriDot);
				beginTriDot.addEventListener(MouseEvent.MOUSE_DOWN, onTriggerMouseDown);
				initTriggerMats();
			}
			else
			{
				beginTriDot.removeEventListener(MouseEvent.MOUSE_DOWN, onTriggerMouseDown);
				triggerLayer.removeChild(beginTriDot);
				this.removeChild(triggerLayer);
				dotsDic = new Dictionary;
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
			if(isActive)
				enableEdit(value);
		}
		
		override public function initFromData(data:Object):void
		{
			this.id = data.id;
			this.x = data.x/2;
			this.y = -data.y/2;
			this.rect = new Rectangle(0, -data.height, data.width, data.height);
			initRectDots();
			this.triggerMatIds = data.objs as Array;
			if(data.hasOwnProperty("triggerTime"))
				this.triggerTime = data.triggerTime;
		}
		
		override public function toExportData():Object
		{
			var obj:Object = new Object;
			obj.id = this.id;
			obj.type = type;
			obj.x = (rect.x+this.x)*2;
			obj.y = Number(-(rect.bottom+this.y)*2);
			obj.width = rect.width;
			obj.height = rect.height;
			if(this.triggerTime > 0)
				obj.triggerTime = this.triggerTime;
			obj.objs = triggerMatIds;
			return obj;
		}
		
		private function save():void
		{
			
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
			if(editable)
			{
				beginTriDot.x = rect.x+rect.width*0.5;
				beginTriDot.y = rect.y+rect.height*0.5;
				
				triggerLayer.graphics.clear();
				if(controlDot)
				{
					triggerLayer.graphics.lineStyle(1, 0.5);
					triggerLayer.graphics.moveTo(beginTriDot.x, beginTriDot.y);
					triggerLayer.graphics.lineTo(controlDot.x, controlDot.y);
				}
				for(var id in dotsDic)
				{
					var mat:EditBase = view.matsControl.getMat(id);
					if(mat)
					{
						var pos:Point = this.globalToLocal(mat.parent.localToGlobal(new Point(mat.x, mat.y)));
						dotsDic[id].x = pos.x;
						dotsDic[id].y = pos.y;
						triggerLayer.graphics.lineStyle(1, 0.5);
						triggerLayer.graphics.moveTo(beginTriDot.x, beginTriDot.y);
						triggerLayer.graphics.lineTo(pos.x, pos.y);
					}
					else
					{
						removeATrigger(id);
					}
				}
			}
			
		}
		
		private function updateRect():void
		{
			if(currId != -1)
			{
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
			}
			
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
		
		private function onEnterFrame(e:Event):void
		{
			if(currId != -1)
			{
				updateRect();
			}
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
			
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			e.stopPropagation();
			var dot:Sprite = e.currentTarget as Sprite;
			dot.stopDrag();
			currId = -1;
		}
	}
}