package 
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	
	import formationEdit.FormationSprite;
	
	public class FormationSelector extends UIComponent
	{
		private var mNumOfForms:int = 0;
		private var mSelected:FormationSprite = null;
		
		public function FormationSelector()
		{
			var self:FormationSelector = this;
			Runtime.getInstance().addEventListener( Runtime.SELECT_DATA_CHANGE,
				function(e:Event):void {
					if( !Runtime.getInstance().selectedFormationType && self.mSelected )
					{
						self.mSelected.select( false );
						self.mSelected = null;
					}
				}
			);
			
			Runtime.getInstance().addEventListener( Runtime.FORMATION_DATA_CHANGE,
				function(e:Event):void {
					self.refresh();
				}
			);
			
			this.refresh();
		}
		
		private function refresh():void
		{
			this.removeChildren();
			var formations:* = Data.getInstance().formationSet;
			for( var fid:String in formations )
			{
				this.insert( fid );
			}
		}
		
		private function insert( fid:String ):void
		{
			var self:FormationSelector = this;
			var menu:ContextMenu = new ContextMenu;
			
			var deleteItem:ContextMenuItem = new ContextMenuItem("删除");
			deleteItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void
				{
					Data.getInstance().eraseFormationById( fid );
					self.refresh();
				}
			);
			
			var renameItem:ContextMenuItem = new ContextMenuItem("重命名");
			renameItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent):void {	
					Utils.makeRenamePanel( function( to:String=null ):void {
						if( !to ) return;
						var formation:* = Data.getInstance().getFormationById( to )
						if( formation ) 
							Alert.show("【错误】该阵型名已经存在!");
						else
						{
							var data:Object = Data.getInstance().getFormationById( fid );
							Data.getInstance().eraseFormationById( fid );
							Data.getInstance().updateFormationSetById( to, data );
							self.refresh();
						}
					}, self);
				}
			);
			
			menu.addItem(deleteItem);
			menu.addItem(renameItem);
			
			var pos:Point = Utils.makeGrid(new Point(20, 60), 80, 3, this.mNumOfForms++);
			var view:FormationSprite = new FormationSprite(fid);
			with( view ) {
				x = pos.x; y = pos.y; 
			}
			view.trim(50);
			view.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
				{
					if( self.mSelected ) self.mSelected.select(false);
					
					if( self.mSelected != view ) 
					{
						self.mSelected = view;
						self.mSelected.select(true);
						Runtime.getInstance().selectedFormationType = fid;
					}
				}
			);
				
			view.contextMenu = menu;
			this.addChild(view);
			
			this.height = view.y+20;
		}
	}
}