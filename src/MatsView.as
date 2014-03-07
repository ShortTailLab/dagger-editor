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
	
	import Trigger.EditTriggers;
	
	import behaviorEdit.BTEditPanel;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
	import mapEdit.EditBase;
	import mapEdit.MatSprite;
	import mapEdit.TriggerSprite;
	
	public class MatsView extends UIComponent
	{
		public var selected:EditBase = null;
		private var matsLayer:UIComponent = null;
		private var labelContainer:UIComponent = null;
		private var mats:Array = null;
		private var matsOnShow:Array = null;
		
		private var grid_width:int = 110;
		private var grid_height:int = 150;
		
		public function MatsView()
		{
			mats = new Array;
			
			init();
			EventManager.getInstance().addEventListener(EventType.ENEMY_DATA_UPDATE, init); 
		}
		
		public function init(e:GameEvent = null):void
		{
			MapEditor.getInstance().addLog("刷新资源列表..");
			while(mats.length > 0)
			{
				MapEditor.getInstance().addLog("pop mats, length "+mats.length);
				var m:EditBase = mats.pop();
			}
			this.removeChildren();
			
			var searchFrame:TextInput = new TextInput;
			searchFrame.prompt = "搜索";
			searchFrame.width = 100;
			searchFrame.height = 20;
			searchFrame.x = 10;
			searchFrame.y = 10;
			searchFrame.addEventListener(Event.CHANGE, onTextChange);
			this.addChild(searchFrame);
			
			matsLayer = new UIComponent;
			this.addChild(matsLayer);
			labelContainer = new UIComponent;
			this.addChild(labelContainer);
			
			var triggerMat:EditBase = new TriggerSprite();
			triggerMat.trim(70);
			addMat(triggerMat);
			
			//var data:Object = Data.getInstance().enemy_profile;
			var data:Object = Data.getInstance().getCurrentLevelEnemyProfile();
			for(var item in data)
			{
				var view:EditBase = new MatSprite(null, item, 100, 70);
				addMat(view);
			}
			mats.sort(function(a, b):int{
				if(int(a.type) < int(b.type))
					return -1;
				else
					return 1;
			});
			resize(mats, 2);
		}
		
		//---------------------
		// actions
		//---------------------
		public function addMat(view:EditBase):void
		{
			view.doubleClickEnabled = true;
			view.mouseChildren = false;
			
			view.addEventListener(MouseEvent.DOUBLE_CLICK, onMatDoubleClick);
			view.addEventListener(MouseEvent.CLICK, onMatClick);
			
			mats.push(view);
			
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
				PopUpManager.addPopUp(btPanel, this);
				PopUpManager.centerPopUp(btPanel);
				btPanel.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-btPanel.width/2;
				btPanel.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-btPanel.height/2;
			}
		}
		
		public function selectItem(target:EditBase):void
		{
			var prev:EditBase = selected;
			if(target != selected)
			{
				selected = target;
				selected.select(true);
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
		
		//------------------------
		// event handlers
		//------------------------
		public function onMatClick(e:MouseEvent):void
		{
			var target:EditBase = e.currentTarget as EditBase;
			selectItem(target);
		}
		
		public function onMatDoubleClick(e:MouseEvent):void
		{
			var target = e.currentTarget as MatSprite
			if(target)
				openBehaviorEditor(target);
		}
		
		private function onTextChange(e:Event):void
		{
			var text:String = TextInput(e.target).text;
			matsOnShow = mats.filter(function(a, index:int, arr:Array):Boolean{
				var type:String = a.type as String;
				return (type.search(text) == 0);
			});
			resize(matsOnShow);
		}
		
		private function resize(matArray:Array, cols:int = 2):void
		{
			while(matsLayer.numChildren>0)
			{
				var m = matsLayer.removeChildAt(matsLayer.numChildren-1);
				m.removeEventListener(MouseEvent.CLICK, onMatClick);
				m.removeEventListender(MouseEvent.DOUBLE_CLICK, onMatDoubleClick);
			}
			labelContainer.removeChildren();
			
			if(matArray.length > 0)
			{
				var prev:String = "";
				var px:int = 0;
				var py:int = 0;
				var xCount:int = 0;
				for(var i:int = 0; i < matArray.length; i++)
				{
					var type:String = String(matArray[i].type);
					if(type.length == 7)
					{
						var curr:String = type.substr(1, 4);
						if(curr != prev)
						{
							var label:TextField = Utils.getLabel("章节 "+curr.substr(0, 2)+" 关卡 "+curr.substr(2, 2), 10, py+40, 18);
							label.width = 200;
							label.height = label.textHeight + 10;
							label.selectable = false;
							label.setTextFormat(new TextFormat(null, 18, 0xff0000)); 
							labelContainer.addChild(label);
							
							xCount = 0;
							py += 30;
							prev = curr;
						}
					}
					
					px = 60+xCount*grid_width;
					if(xCount == 0)
						py += grid_height;
					
					matArray[i].x = px;
					matArray[i].y = py;
					matsLayer.addChild(matArray[i]);
					
					xCount++;
					xCount = xCount%cols;
				}
				this.height = matArray[matArray.length-1].y+130;
			}
		}
	}
}