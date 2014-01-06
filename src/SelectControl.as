package
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	
	public class SelectControl extends EventDispatcher
	{
		public var targets:Array = null;
		public var view:EditView = null;
		
		public function SelectControl(_view:EditView)
		{
			targets = new Array;
			this.view = _view;
		}
		
		public function select(target:MatSprite):void
		{
			if(targets.length == 1 && targets[0] == target)
				return;
			unselect();
			add(target);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		private function add(target:MatSprite):void
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
				for each(var m:MatSprite in copy)
				{
					view.removeMat(m);
				}
			});
			menu.addItem(item);
			menu.addItem(item2);
			menu.addItem(item3);
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
		
		public function unselect(target:MatSprite = null):void
		{
			for(var i:int = targets.length-1; i >= 0; i--)
				if(!target)
				{
					var o:MatSprite = targets.pop()
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
			if(e.target as MatSprite)
				unselect(e.target as MatSprite);
		}
	}
}