package
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.UIComponent;
	
	public class FormationsView extends UIComponent
	{
		private var formsNum:int = 0;
		public var selected:FormationSprite = null;
		
		public function FormationsView()
		{
			init();
			
			Formation.getInstance().addEventListener(MsgEvent.ADD_FORMATION, onAdd);
			Formation.getInstance().addEventListener(MsgEvent.REMOVE_FORMATION, onRemove);
		}
		
		private function init():void
		{
			formsNum = 0;
			this.removeChildren();
			
			for(var name in Formation.getInstance().formations)
			{
				add(name);
			}
		}
		
		private function onAdd(e:MsgEvent):void
		{
			add(e.hintMsg);
		}
		private function onRemove(e:MsgEvent):void
		{
			init();
		}
		
		private function add(name:String):void
		{
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("删除");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				Formation.getInstance().remove(logo.fName);
			});
			menu.addItem(item);
			
			var logo:FormationSprite = new FormationSprite(name);
			var pos:Point = Utils.makeGrid(new Point(20, 60), 80, 3, formsNum++);
			logo.x = pos.x;
			logo.y = pos.y;
			logo.trim(50);
			logo.addEventListener(MouseEvent.CLICK, onClick);
			logo.contextMenu = menu;
			addChild(logo);
			this.height = logo.y+20;
		}
		private function onClick(e:MouseEvent):void
		{
			var target:FormationSprite = e.currentTarget as FormationSprite;
			var prev:FormationSprite = selected;
			if(selected)
			{
				selected.select(false);
				selected = null;
			}
			if(target != prev)
			{
				selected = target;
				selected.select(true);
			}
		}
	}
}