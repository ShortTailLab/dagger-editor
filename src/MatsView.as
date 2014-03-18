package
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import spark.components.TextInput;
	import spark.components.VGroup;
	
	import Trigger.EditTriggers;
	
	import behaviorEdit.BTEditPanel;

	import mapEdit.EditBase;
	import mapEdit.MatSprite;
	import mapEdit.TriggerSprite;
	
	public class MatsView extends VGroup
	{
		private var matsLayer:UIComponent = null;	
		private var mats:Array = new Array;
		
		private var GRID_WIDTH:int = 100;
		private var GRID_HEIGHT:int = 100;
		
		public var selected:EditBase = null;
		
		public function MatsView()
		{	
			// style this
			this.paddingLeft = 5;
			this.paddingTop = 5;
			this.gap = 0;
			this.autoLayout = true;
			
			// search box
			var searchFrame:TextInput = new TextInput;
			searchFrame.prompt = "搜索";
			searchFrame.percentWidth = 100;
			searchFrame.height = 30;
			searchFrame.addEventListener(Event.CHANGE, onTextChange);
			this.addElement(searchFrame);
			
			matsLayer = new UIComponent;
			this.addElement(matsLayer);
		}
		
		private function hookEventsToItem(view:EditBase):void
		{
			view.doubleClickEnabled = true;
			view.mouseChildren = false;
			
			view.addEventListener(MouseEvent.DOUBLE_CLICK, onMatDoubleClick);
			view.addEventListener(MouseEvent.CLICK, onMatClick);
						
			var menu:ContextMenu = new ContextMenu;
			var bhButton:ContextMenuItem = new ContextMenuItem("行为");
			bhButton.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				var target:MatSprite = e.contextMenuOwner as MatSprite;
				if(target)
					openBehaviorEditor(target);
			});
			menu.addItem(bhButton);
			
			var trigger:ContextMenuItem = new ContextMenuItem("触发器");
			var self = this;
			trigger.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,
				function(e:ContextMenuEvent)
				{
					var target:MatSprite = e.contextMenuOwner as MatSprite;
					if(target)
						openTriggerEditor(target);
				});
			menu.addItem(trigger);
			
			view.contextMenu = menu;
		}
		
		//---------------------
		// actions
		//---------------------
		private function openTriggerEditor(target:MatSprite):void
		{
			if(target)
			{ 
				var win:EditTriggers = new EditTriggers(target);
				PopUpManager.addPopUp(win, MapEditor.getInstance());
				PopUpManager.centerPopUp(win);
				win.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-win.width/2;
				win.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-win.height/2;
			}
		}
		
		private function openBehaviorEditor(target:MatSprite):void
		{
			if(target)
			{
				var btPanel:BTEditPanel = new BTEditPanel(target);
				PopUpManager.addPopUp(btPanel, MapEditor.getInstance());
				PopUpManager.centerPopUp(btPanel);
				btPanel.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-btPanel.width/2;
				btPanel.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-btPanel.height/2;
			}
		}
		
		public function selectItem(target:EditBase):void
		{
			if(target != selected)
			{
				clearSelection();
				
				// select curr
				selected = target;
				selected.select(true);
			}
			else if(selected)
			{
				clearSelection();
			}
		}
		
		public function clearSelection():void
		{
			if(selected)
			{
				selected.select(false);
				selected = null;
			}
		}
		
		public function refreshDataAndView(matData:Object, cols:int = 2):void
		{
			// explicitly remove mats array
			mats = null;
			mats = new Array;
			
			var triggerMat:EditBase = new TriggerSprite();
			triggerMat.trim(70);
			hookEventsToItem(triggerMat);
			mats.push(triggerMat);
			
			for(var item in matData)
			{
				var view:EditBase = new MatSprite(null, item, 80, 90);
				hookEventsToItem(view);
				mats.push(view);
			}
			
			mats.sort(function(a, b):int{
				if(int(a.type) < int(b.type))
					return -1;
				else
					return 1;
			}); 
			
			refreshView(mats);
		}
		
		//------------------------
		// event handlers
		//------------------------
		private function onMatClick(e:MouseEvent):void
		{
			var target:EditBase = e.currentTarget as EditBase;
			selectItem(target);
		}
		
		private function onMatDoubleClick(e:MouseEvent):void
		{
			var target:MatSprite = e.currentTarget as MatSprite;
			if(target)
				openBehaviorEditor(target);
		}
		
		private function onTextChange(e:Event):void
		{
			var text:String = TextInput(e.target).text;
			var matsToShow:Array = mats.filter(function(a, index:int, arr:Array):Boolean
			{
				var type:String = a.type as String;
				return (type.search(text) == 0);
			});
			
			// refresh view only, do not change data
			refreshView(matsToShow);
		}
		
		private function refreshView(matViewArray:Array, cols:int = 2):void
		{
			// always clear mats layer
			matsLayer.removeChildren();

			if(matViewArray.length == 0)
				return;
			
			var prev:String = "";
			var px:int = 0;
			var py:int = 0;
			var xCount:int = 0;
			
			for(var i:int = 0; i < matViewArray.length; i++)
			{
				var matView:EditBase = matViewArray[i];
				var type:String = String(matView.type);
				if(type.length == 7)
				{
					var curr:String = type.substr(1, 4);
					if(curr != prev)
					{
						// insert a chapter label
						var label:TextField = Utils.getLabel("章节 "+curr.substr(0, 2)+" 关卡 "+curr.substr(2, 2), 10, py+40, 18);
						label.width = 200;
						label.height = label.textHeight + 10;
						label.selectable = false;
						label.setTextFormat(new TextFormat(null, 18, 0xff0000)); 
						matsLayer.addChild(label);
						
						xCount = 0;
						py += 30;
						prev = curr;
					}
				}
				
				px = 60+ xCount*GRID_WIDTH;
				if(xCount == 0)
					py += GRID_HEIGHT;
				
				matView.x = px;
				matView.y = py;
				matsLayer.addChild(matView);
				
				xCount++;
				xCount = xCount%cols;
			}
			
			this.height = matViewArray[matViewArray.length-1].y + 130;
		}
	}
}