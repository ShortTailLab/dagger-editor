package editEntity
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;

	public class TriggerSprite extends EditBase
	{
		private var dots:Vector.<Sprite> = new Vector.<Sprite>;
		
		public static var TRIGGER_TYPE:String = "AreaTrigger";
		private var rect:Rectangle = null;
		public var beginTriDot:Sprite = null;
		public var triggerMatIds:Array = null;
		public var dotsDic:Dictionary = null;
		private var triggerLayer:Sprite;
		private var editable:Boolean = false;
		
		public function TriggerSprite(_editView:EditView = null)
		{
			super(_editView, TRIGGER_TYPE);
			//左上角为原点
			rect = new Rectangle(-50, -100, 100, 100);
			triggerMatIds = new Array;
			dotsDic = new Dictionary;
			initRectDots();
			
			if(editView)
			{
				this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
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
			{
				var dot:Sprite = dots.pop() as Sprite;
				dot.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				dot.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				this.removeChild(dot);
			}
			
			addDot(rect.x, rect.y);
			addDot(rect.right, rect.y);
			addDot(rect.right, rect.bottom);
			addDot(rect.x, rect.bottom);
			updateRect();
			
			if(editView)
			{
				for(var i:int = 0; i < 4; i++)
				{
					dots[i].addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
					dots[i].addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				}
			}
		}
		
		public function addATrigger(mat:EditBase):void
		{
			if(dotsDic.hasOwnProperty(id))
				return;
			if(mat.triggerId.length > 0)
			{
				Alert.show("不能重复trigger");
				return;
			}
			
			var dot:Sprite = createDot();
			dot.addEventListener(MouseEvent.MOUSE_DOWN, onTirggerDotMouseDown);
			triggerLayer.addChild(dot);
			dotsDic[mat.id] = dot;
			triggerMatIds.push(mat.id);
			mat.triggerId = this.id;
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
					editView.matsControl.getMat(id).triggerId = "";
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
			dot.graphics.lineStyle(1);
			dot.graphics.beginFill(0);
			dot.graphics.drawCircle(0, 0, 10);
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
			{
				var mat:EditBase = editView.matsControl.getMat(id);
				addATrigger(mat);
			}
				
			triggerLayer.removeChild(controlDot);
			controlDot = null;
		}
		
		private function findId(globalPos:Point):String
		{
			var mats:Array = editView.matsControl.getMatByPoint(globalPos);
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
		
		override public function onDelete():void
		{
			for each(var id:String in triggerMatIds)
			{
				editView.matsControl.getMat(id).triggerId = "";
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
			
			if(this.editView)
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
			if(data.hasOwnProperty("triggerId") && editView.matsControl.getMat(data.triggerId))
				this.triggerId = data.triggerId;
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
			if(this.triggerId.length > 0)
				obj.triggerId = this.triggerId;
			return obj;
		}
		
		private function save():void
		{
			
		}
		
		private function addDot(px:int, py:int):void
		{
			var dot:Sprite = createDot();
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
					var mat:EditBase = editView.matsControl.getMat(id);
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
			trace("dot mouse down");
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