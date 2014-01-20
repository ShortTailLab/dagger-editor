package
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	
	import editEntity.EditBase;
	
	
	public class SelectControl extends EventDispatcher
	{
		public var targets:Array = null;
		public var view:EditView = null;
		public var selectFrame:Shape = null;
		private var selectRect:Rectangle = null;
		public var isSelecting:Boolean = false;
		
		public function SelectControl(_view:EditView)
		{
			targets = new Array;
			this.view = _view;
			selectRect = new Rectangle;
		}
		
		public function select(target:EditBase):void
		{
			if(targets.length == 1 && targets[0] == target)
				return;
			unselect();
			add(target);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		
		public function onBeginSelect(px:Number, py:Number):void
		{
			selectRect.x = px;
			selectRect.y = py;
			isSelecting = true;
		}
		
		public function onUpdateSelect(px:Number, py:Number):void
		{
			if(isSelecting)
			{
				if(!selectFrame)
				{
					selectFrame = new Shape;
					view.map.addChild(selectFrame);
				}
				selectRect.width = px - selectRect.x;
				selectRect.height = py - selectRect.y;
				updateSelectRect();
			}
		}
		
		public function onEndSelect():void
		{
			isSelecting = false;
			if(selectFrame)
			{
				selectMul(getSelectMats(selectFrame));
				view.map.removeChild(selectFrame);
				selectFrame = null;
			}
		}
		
		private function getSelectMats(frame:DisplayObject):Array
		{
			var result:Array = new Array;
			for each(var m:EditBase in view.matsControl.mats)
			if(m.hitTestObject(frame))
				result.push(m);
			return result;
		}
		
		private function updateSelectRect():void
		{
			selectFrame.graphics.clear();
			if(isSelecting && selectRect)
			{
				selectFrame.x = selectRect.x;
				selectFrame.y = selectRect.y;
				selectFrame.graphics.lineStyle(1);
				selectFrame.graphics.drawRect(0, 0, selectRect.width, selectRect.height);
			}
		}
		
		private function add(target:EditBase):void
		{
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("复制");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				view.copySelect();
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
		
		private function onRemoved(e:Event):void
		{
			if(e.target as EditBase)
				unselect(e.target as EditBase);
		}
	}
}