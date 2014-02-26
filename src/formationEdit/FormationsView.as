package formationEdit
{
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import manager.EventManager;
	import tools.RenamePanel;
	import tools.Utils;
	
	public class FormationsView extends UIComponent
	{
		private var formsNum:int = 0;
		public var selected:FormationSprite = null;
		
		public function FormationsView()
		{
			init();
			
			Formation.getInstance().addEventListener(MsgEvent.ADD_FORMATION, onAdd);
			EventManager.getInstance().addEventListener(MsgEvent.FORMATION_CHANGE, onChange);
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
		private function onChange(e:MsgEvent):void
		{
			init();
		}
		
		private function add(name:String):void
		{
			var menu:ContextMenu = new ContextMenu;
			var item:ContextMenuItem = new ContextMenuItem("删除");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				Formation.getInstance().remove(logo.fName);
				EventManager.getInstance().dispatchEvent(new MsgEvent(MsgEvent.FORMATION_CHANGE));
			});
			var item2:ContextMenuItem = new ContextMenuItem("重命名");
			var self:FormationsView = this;
			item2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				var from:String = (e.contextMenuOwner as FormationSprite).fName;
				var window:RenamePanel = new RenamePanel;
				window.addEventListener(MsgEvent.RENAME_LEVEL, function(e:MsgEvent):void{
					var to:String = e.hintMsg;
					if(Formation.getInstance().hasFormation(to))
						Alert.show("命名已存在！");
					else
					{
						Formation.getInstance().rename(from, to);
						EventManager.getInstance().dispatchEvent(new MsgEvent(MsgEvent.FORMATION_CHANGE));
					}
				});
				
				PopUpManager.addPopUp(window, self, true);
				PopUpManager.centerPopUp(window);
			});
			menu.addItem(item);
			menu.addItem(item2);
			
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