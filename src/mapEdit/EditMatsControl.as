package mapEdit
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	public class EditMatsControl
	{
		public var mats:Array;
		private var view:MainScene;
		
		static private var idCount:int = 0;
		
		public function EditMatsControl(_view:MainScene)
		{
			mats = new Array;
			view = _view;
			view.addEventListener(MouseEvent.MOUSE_MOVE, onMatMove);
		}
		
		public function init(data:Object):void
		{
			for each(var item:Object in data)
			{
				if(!item.hasOwnProperty("id"))
					item.id = getUID();
				
				var mat:Component = MatFactory.createMatOnView(view, item.type, 30);
				mat.initFromData(item);
				addMat(mat);
			}
		}
		
		public function getMatsData():Array
		{
			var data:Array = new Array;
			for each(var m:Component in mats)
			{
				if(m.triggerId.length > 0 && !getMat(m.triggerId))
					m.triggerId = "";
					
				data.push(m.toExportData());
			}
			return data;
		}
		
		public function getMat(sid:String):Component
		{
			for each(var m:Component in mats)
				if(m.sid == sid)
					return m;
			return null;
		}
		
		public function getMatsByPoint(pos:Point):Array
		{
//			var localPos:Point = view.mapView.globalToLocal(pos);
//			var result:Array = new Array;
//			for each(var m:Component in mats)
//			{
//				var bound:Rectangle = m.getBounds(m.parent);
//				if(bound.contains(localPos.x, localPos.y))
//					result.push(m);
//			}
			//return result;
			return [];
		}
		
		public function add(type:String, px:int, py:int):Component
		{
			var mat:Component = MatFactory.createMatOnView(view, type, 30);
			
			mat.x = px;
			mat.y = py;
			addMat(mat);
			return mat;
		}
		
		private function addMat(mat:Component):void
		{
//			if(mat.sid == "" || !mat.sid)
//				mat.sid = getUID();
//
//			view.mapView.addChild(mat);
//			mats.push(mat);
//			mat.doubleClickEnabled = true;
//			mat.addEventListener(MouseEvent.CLICK, onMatClick);
//			mat.addEventListener(MouseEvent.MOUSE_DOWN, onMatMouseDown);
//			mat.addEventListener(MouseEvent.MIDDLE_CLICK, onMatMiddleClick);
//			mat.addEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
		}
		
		public function remove(id:String):void
		{
			for(var i:int = 0; i < mats.length; i++)
				if(Component(mats[i]).sid == id)
				{
//					Component(mats[i]).onDelete();
//					mats[i].removeEventListener(MouseEvent.MOUSE_DOWN, onMatMouseDown);
//					mats[i].removeEventListener(MouseEvent.MIDDLE_CLICK, onMatMiddleClick);
//					mats[i].removeEventListener(MouseEvent.MOUSE_UP, onMatMouseUp);
//					view.mapView.removeChild(mats[i]);
//					mats.splice(i, 1);
					break;
				}
		}
		
		public function clear():void
		{
//			for each(var m:Component in mats)
//				view.mapView.removeChild(m);
//			mats.splice(0, mats.length);
		}
		
		private function getUID():String
		{
			return new Date().time+String(idCount++);
		}
		
		private var draggingMats:Array = null;
		private var isClick:Boolean =false;
		private var currX:Number = 0.0;
		private var currY:Number = 0.0;
		private function onMatMouseDown(e:MouseEvent):void
		{
			e.stopPropagation();
			isClick = true;
			currX = view.mouseX;
			currY = view.mouseY;
			var _draggingMat:Component = e.currentTarget as Component;
			
//			if(_draggingMat.isSelected)
//				draggingMats = view.selectControl.targets;
//			else
//				draggingMats = new Array(e.currentTarget as Component);
			
		}
		private function onMatMove(e:MouseEvent):void
		{
			isClick = false;
			if(draggingMats && draggingMats.length > 0)
			{
				var dx:Number = view.mouseX - currX;
				var dy:Number = view.mouseY - currY;
				if(dx != 0 || dy != 0)
				{
					for each(var m:Sprite in draggingMats)
					{
						m.x += dx;
						m.y += dy;
					}
				}
			}
			
			currX = view.mouseX;
			currY = view.mouseY;
		}
		
		private function onMatMouseUp(e:MouseEvent):void {
			draggingMats = null;
			
//			if(isClick)
//			{
//				var target:Component = e.currentTarget as Component;
//				view.selectControl.select(target);
//			}
//			isClick =false;
		}
		
		private function onMatMiddleClick(e:MouseEvent):void {
			e.stopPropagation();
		}
		
		private const kDOUBLE_CLICK_SPEED:int = 300;
		private var doubleClickTimer:Timer = null;
		private function onMatClick(e:MouseEvent):void
		{
			if( this.doubleClickTimer )
			{
				// double click
				var target:Component = e.currentTarget as Component;
				var targetOfSameType:Array = new Array;
				for each(var m:Component in view.matsControl.mats)
				if(m.type == target.type)
					targetOfSameType.push(m);
//				view.selectControl.selectMul(targetOfSameType);	
				
				this.doubleClickTimer = null;
			} else {
				// single click
				
				this.doubleClickTimer = new Timer(this.kDOUBLE_CLICK_SPEED, 1);
				var self:* = this;
				this.doubleClickTimer.addEventListener( TimerEvent.TIMER,
					function():void
					{
						self.doubleClickTimer = null;
					});
				this.doubleClickTimer.start();
			}
		}
	}
}