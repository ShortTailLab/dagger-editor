package Trigger
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.controls.ComboBox;
	import mx.core.UIComponent;
	
	import Trigger.TriggerEvent;
	
	import manager.EventManager;
	
	// ActionScript file
	
	class TNode extends UIComponent
	{
		public static const WIDTH:Number = 380;
		public static const HEIGHT:Number = 25;
		public static const HOR_PADDING:Number = 30;
		public static const VER_PADDING:Number = 30;
		
		public static const BG_COLOR = 0xF0FFF0;
		
		private var cond:String = "";
		private var result:String = "";
		
		private var background:Sprite = null;
		private var enumCond:ComboBox = null;
		private var enumResult:ComboBox = null;
		
		private var condArgs:UIComponent = null;
		private var retArgs:UIComponent = null;
		private var condItems:Object = {};
		private var retItems:Object = {};
		
		public function TNode(_condType:String = "", _retType = "")
		{
			super();
			this.cond = _condType;
			this.result = _retType;
			
			// create frame
			this.background = new Sprite;
			this.addChild(this.background);
			this.resize(TNode.WIDTH, this.getHeight());
			
			this.condArgs = new UIComponent;
			this.condArgs.x = 10; this.condArgs.y = 45;
			this.retArgs  = new UIComponent;
			this.retArgs.x = 180; this.retArgs.y = 45;
			this.addChild(this.condArgs);
			this.addChild(this.retArgs);
			
			var conds:Object 	= Data.getInstance().dynamic_args.TriggerCond;
			var rets:Object 	= Data.getInstance().dynamic_args.TriggerResult;
			
			var conds_arr:Array = [], rets_arr:Array = [];
			for( var key:String in conds ) conds_arr.push(key);
			for( var key:String in rets ) rets_arr.push(key);
			
			var cond:TextField = Utils.getLabel("条件类型：", 10, 12.5, 14);
			this.addChild(cond);
			this.enumCond = new ComboBox();
			this.enumCond.dataProvider = new ArrayCollection(conds_arr);
			this.enumCond.x = 90; this.enumCond.y = 10; 
			this.enumCond.width = 80; this.enumCond.height = TNode.HEIGHT;
			this.enumCond.prompt = "条件";
			this.enumCond.editable = false;
			this.addChild(this.enumCond);
			
			var cond:TextField = Utils.getLabel("结果类型：", 180, 12.5, 14);
			this.addChild(cond);			
			this.enumResult = new ComboBox();
			this.enumResult.dataProvider = new ArrayCollection(rets_arr);
			this.enumResult.x = 260; this.enumResult.y = 10; 
			this.enumResult.width = 80; this.enumResult.height = TNode.HEIGHT;
			this.enumResult.prompt = "功能";
			this.enumResult.editable = false;
			this.addChild(this.enumResult);
			
			var menu:ContextMenu = new ContextMenu;
			this.contextMenu = menu;
			
			var btn:ContextMenuItem = new ContextMenuItem("删除");
			var self = this;
			btn.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, 
				function(e:ContextMenuEvent){
					var e2 = new TriggerEvent(self, TriggerEvent.REMOVE_TRIGGER);	
					EventManager.getInstance().dispatchEvent( e2 );
				});
			menu.addItem(btn);
			
			this.enumCond.addEventListener(Event.CHANGE, onCondTypeChange);
			this.enumResult.addEventListener(Event.CHANGE, onRetTypeChange);
		}
		
		private function onCondTypeChange(e:Event):void
		{
			var type = e.target.selectedItem;
			var dynamics = Data.getInstance().dynamic_args;
			
			this.condArgs.removeChildren();
			if( dynamics[type] )
			{
				for( var key:* in dynamics[type] )
				{
					if( dynamics[type][key] == "float" )
					{
						var len = this.condArgs.numChildren;
						var label:TextField = Utils.getLabel(key, 0, len*(10+TNode.HEIGHT)+-10, 14);
						this.condArgs.addChild(label);
					}
				}
			}
			
			this.resize( TNode.WIDTH, this.getHeight() );
		}
		
		private function onRetTypeChange(e:Event):void
		{
			var type = e.target.selectedItem;
			var dynamics = Data.getInstance().dynamic_args;
			
			this.retArgs.removeChildren();
			if( dynamics[type] )
			{
				for( var key:* in dynamics[type] )
				{
					if( dynamics[type][key] == "float" )
					{
						var len = this.retArgs.numChildren;
						var label:TextField = Utils.getLabel(key, 0, len*(10+TNode.HEIGHT)+-10, 14);
						this.retArgs.addChild(label);
					}
				}
			}
			
			this.resize( TNode.WIDTH, this.getHeight() );
		}
		
		public function setPosition(_x:Number, _y:Number) :void
		{
			this.x = _x; this.y = _y;	
		}
		
		public function getHeight():int
		{
			//var items = Math.max(this.condArgs.numChildren, this.retArgs.numChildren);
			//var num = this.retArgs.numChildren;
			var num = 3;
			return (TNode.HEIGHT+10)*num+10;
		}
		
		private function resize(_width:Number, _height:Number): void
		{
			background.graphics.clear();
			background.graphics.lineStyle(1);
			background.graphics.beginFill(TNode.BG_COLOR);
			background.graphics.drawRect(
				0, 0, _width, _height
			);
			background.graphics.endFill();
		}
		
		public function isDone():Boolean
		{
			return enumCond.selectedIndex != -1 && enumResult.selectedIndex != -1;
		}
	}

}