package
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import spark.primitives.Rect;
	
	import editEntity.EditBase;
	
	
	public class SelectControl extends EventDispatcher
	{
		public var targets:Array = null;
		public var view:EditView = null;
		private var selectFrame:Shape = null;
		
		public function SelectControl(_view:EditView)
		{
			targets = new Array;
			this.view = _view;
			
			this.view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			this.view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		public function select(target:EditBase):void
		{
			if(targets.length == 1 && targets[0] == target)
				return;
			unselect();
			add(target);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function isSelecting():Boolean
		{
			return selectFrame;
		}
		
		public function update(dt:int):void
		{
			
		}
		
		private function onMouseDown(e:MouseEvent):void
		{
			var pos:Point = view.globalToLocal(new Point(e.stageX, e.stageY));
			selectFrame = new Shape;
			selectFrame.x = pos.x;
			selectFrame.y = pos.y;
			view.addChild(selectFrame);
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			if(selectFrame)
			{
				var pos:Point = view.globalToLocal(new Point(e.stageX, e.stageY));
				selectFrame.graphics.clear();
				selectFrame.graphics.lineStyle(1);
				selectFrame.graphics.drawRect(0, 0, pos.x-selectFrame.x, pos.y-selectFrame.y);
			}
		}
		
		private function onMouseUp(e:MouseEvent):void
		{
			if(selectFrame)
			{
				selectMul(getSelectMats(selectFrame.getBounds(view)));
				view.removeChild(selectFrame);
				selectFrame = null;
			}
		}
		
		private function getSelectMats(frame:Rectangle):Array
		{
			var result:Array = new Array;
			for each(var m:EditBase in view.matsControl.mats)
			{
				var bound:Rectangle = m.getBounds(view);
				if(frame.intersects(bound))
					result.push(m);
			}
			return result;
		}
		
		private function add(target:EditBase):void
		{
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("复制");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				copySelect();
			});
			var item2:ContextMenuItem = new ContextMenuItem("设为阵型");
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				Formation.getInstance().add(targets);
			});
			var item3:ContextMenuItem = new ContextMenuItem("删除");
			item3.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				var copy:Array = targets.slice(0, targets.length);
				for each(var m:EditBase in copy)
				{
					view.matsControl.remove(m.id);
				}
			});
			menu.addItem(item);
			menu.addItem(item2);
			menu.addItem(item3);
			target.parent.setChildIndex(target, target.parent.numChildren-1);
			target.contextMenu = menu;
			target.select(true);
			target.enablePosChangeDispatch(true);
			target.addEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
			targets.push(target);
		}
		
		public function selectMul(targetArr:Array):void
		{
			if(targetArr.length == 0)
				return;
			unselect();
			while(targetArr.length > 0)
				add(targetArr.pop());
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function unselect(target:EditBase = null):void
		{
			for(var i:int = targets.length-1; i >= 0; i--)
				if(!target)
				{
					var o:EditBase = targets.pop()
					o.select(false);
					o.enablePosChangeDispatch(false);
					o.removeEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
					o.contextMenu = null
				}
				else if(target == targets[i])
				{
					target.select(false);
					target.enablePosChangeDispatch(false);
					target.removeEventListener(Event.REMOVED_FROM_STAGE , onRemoved);
					targets.splice(i, 1);
					break;
				}
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function copySelect():void
		{
			var newMats:Array = new Array;
			for each(var m:EditBase in targets)
			{
				newMats.push(view.matsControl.add(m.type, m.x+30, m.y+30));
			}
			selectMul(newMats);
		}
		
		private function onRemoved(e:Event):void
		{
			if(e.target as EditBase)
				unselect(e.target as EditBase);
		}
	}
}