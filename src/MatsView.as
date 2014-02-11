package
{
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	import spark.components.TextInput;
	
	import behaviorEdit.BTEditPanel;
	import behaviorEdit.EditPanel;
	
	import editEntity.EditBase;
	import editEntity.MatSprite;
	import editEntity.TriggerSprite;
	
	import manager.EventManager;
	import manager.EventType;
	import manager.GameEvent;
	
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
			while(mats.length > 0)
			{
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
			add(triggerMat);
			
			var data:Object = Data.getInstance().enemyData;
			for(var item in data)
			{
				var view:EditBase = new MatSprite(null, item, 100, 70);
				add(view);
			}
			mats.sort(function(a, b):int{
				if(int(a.type) < int(b.type))
					return -1;
				else
					return 1;
			});
			resize(mats, 2);
		}
		
		private function add(view:EditBase):void
		{
			view.doubleClickEnabled = true;
			mats.push(view);
			
			var menu:ContextMenu = new ContextMenu;
			var btn2:ContextMenuItem = new ContextMenuItem("行为");
			btn2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent){
				var target:MatSprite = e.contextMenuOwner as MatSprite;
				if(target)
					editBT(target);
			});
			menu.addItem(btn2);
			
			view.contextMenu = menu;
		}
		
		private function edit(target:MatSprite):void
		{
			if(target)
			{ 
				var win:EditPanel = new EditPanel(target);
				PopUpManager.addPopUp(win, this);
				PopUpManager.centerPopUp(win);
				win.x = FlexGlobals.topLevelApplication.stage.stageWidth/2-win.width/2;
				win.y = FlexGlobals.topLevelApplication.stage.stageHeight/2-win.height/2;
			}
		}
		private function editBT(target:MatSprite):void
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
		
		private var isDoubleClick:Boolean = false;
		public function onMatClick(e:MouseEvent):void
		{
			if(isDoubleClick)
			{
				onMatDoubleClick(e);
			}
			else
			{
				isDoubleClick = true;
				var timer:Timer = new Timer(200, 1);
				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e):void{isDoubleClick=false;});
				timer.start();
				
				var target:EditBase = e.currentTarget as EditBase;
				var prev:EditBase = selected;
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
		
		public function onMatDoubleClick(e:MouseEvent):void
		{
			var target = e.currentTarget as MatSprite
			if(target)
				editBT(target);
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
		
		public function resize(matArray:Array, cols:int = 2):void
		{
			while(matsLayer.numChildren>0)
			{
				var m = matsLayer.removeChildAt(matsLayer.numChildren-1);
				m.removeEventListener(MouseEvent.CLICK, onMatClick);
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
					matArray[i].addEventListener(MouseEvent.CLICK, onMatClick);
					matsLayer.addChild(matArray[i]);
					
					xCount++;
					xCount = xCount%cols;
				}
				this.height = matArray[matArray.length-1].y+130;
			}
		}
	}
}