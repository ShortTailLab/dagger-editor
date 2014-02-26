package Trigger
{
	import com.as3xls.xls.Type;
	
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.collections.ArrayCollection;
	import mx.controls.ComboBox;
	import mx.controls.TextInput;
	import mx.core.UIComponent;
	
	import Trigger.TriggerEvent;
	
	import manager.EventManager;
	import tools.Utils;
	
	// ActionScript file
	
	class TNode extends UIComponent
	{
		public static const WIDTH:Number = 380;
		public static const HEIGHT:Number = 25;
		public static const HOR_PADDING:Number = 30;
		public static const VER_PADDING:Number = 30;
		
		public static const BG_COLOR = 0xF0FFF0;
		
		private var background:Sprite = null;
		private var enumCond:ComboBox = null;
		private var enumResult:ComboBox = null;
		
		private var condArgs:UIComponent = null;
		private var retArgs:UIComponent = null;
		private var condItems:Object = {};
		private var retItems:Object = {};
		
		public function getCondType():String { return this.enumCond.selectedItem as String; }
		public function getResultType():String { return this.enumResult.selectedItem as String; }
		
		public function TNode()
		{
			super();
			// create frame
			this.background = new Sprite;
			this.addChild(this.background);
			this.resize(TNode.WIDTH, this.getHeight());
			
			this.condArgs = new UIComponent;
			this.condArgs.x = 10; this.condArgs.y = 35;
			this.retArgs  = new UIComponent;
			this.retArgs.x = 180; this.retArgs.y = 35;
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
			with( this.enumCond ) {
				dataProvider = new ArrayCollection(conds_arr);
				x = 90; y = 10; width = 80; height = TNode.HEIGHT;
				prompt = "条件"; editable = false;
			}
			this.addChild(this.enumCond);
			
			var cond:TextField = Utils.getLabel("结果类型：", 180, 12.5, 14);
			this.addChild(cond);			
			this.enumResult = new ComboBox();
			with( this.enumResult )
			{
				dataProvider = new ArrayCollection(rets_arr);
				x = 260; y = 10; width = 80; height = TNode.HEIGHT;
				prompt = "功能"; editable = false;
			}
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
			
			this.onCondTypeChange();
			this.onRetTypeChange();
		}
		
		public function reset(trigger:Object):void
		{
			this.enumCond.selectedItem = trigger.cond.type;
			this.enumResult.selectedItem = trigger.result.type;
			
			this.condItems = Utils.deepCopy(trigger.cond);
			this.retItems = Utils.deepCopy(trigger.result);
			
			this.onCondTypeChange();
			this.onRetTypeChange();
		}
		
		private function onCondTypeChange(e:Event=null):void
		{
			var type = this.enumCond.selectedItem;
			var dynamics = Data.getInstance().dynamic_args;
			
			this.condArgs.removeChildren();
			if( dynamics[type] )
			{
				for( var key:* in dynamics[type] )
				{
					if( dynamics[type][key] == "float" )
					{
						var len = this.condArgs.numChildren;
						var posy = len/2*(10+TNode.HEIGHT)+10;
						
						var label:TextField = Utils.getLabel(key, 0, posy, 14);
						var text:TextInput = new TextInput();
						var self = this;
						with(text){
							x = 80; y = posy; 
							width = 80; height = TNode.HEIGHT;
							editable = true; text = self.condItems[key] || ""; 
							restrict = '0-9';
						}
						text.addEventListener(Event.CHANGE, (function(nkey) {
							return function(e:Event):void
							{
								self.condItems[nkey] = e.target.text;
							}
						})(key));
						
						this.condArgs.addChild(label);
						this.condArgs.addChild(text);
					}
				}
			}
			
			this.resize( TNode.WIDTH, this.getHeight() );
		}
		
		private function onRetTypeChange(e:Event=null):void
		{
			var type = this.enumResult.selectedItem;
			var dynamics = Data.getInstance().dynamic_args;
			
			this.retArgs.removeChildren();
			if( dynamics[type] )
			{
				for( var key:String in dynamics[type] )
				{
					if( dynamics[type][key] == "float" )
					{
						var len = this.retArgs.numChildren;
						var posy = len/2*(10+TNode.HEIGHT)+10;
						
						var label:TextField = Utils.getLabel(key, 0, posy, 14);
						var text:TextInput = new TextInput();
						var self = this;
						with(text){
							x = 80; y = posy; 
							width = 80; height = TNode.HEIGHT;
							editable = true; text = self.retItems[key] || ""; 
							restrict = '0-9';
						}
						text.addEventListener(Event.CHANGE, (function(nkey) {
							return function(e:Event):void
							{
								self.retItems[nkey] = e.target.text;
							}
						})(key));
						
						this.retArgs.addChild(label);
						this.retArgs.addChild(text);
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
			var num = 1; 
			if( this.condArgs && this.retArgs )
				num += Math.max(this.condArgs.numChildren/2, this.retArgs.numChildren/2);
			num = Math.max(1, num);
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
			var condType = this.enumCond.selectedItem;
			var retType = this.enumResult.selectedItem;
			if( !condType || !retType ) return false;
			
			var dynamics = Data.getInstance().dynamic_args;
			if( condType in dynamics )
				for( var key:* in dynamics[condType] )
					if( !this.condItems.hasOwnProperty(key) || this.condItems[key] == "" ) return false;
 			
			if( retType in dynamics )
				for( var key:* in dynamics[retType] )
					if( !this.retItems.hasOwnProperty(key) || this.retItems[key] == "" ) return false;
			
			return true;
		}

		public function serialize():Object
		{
			var condType = this.enumCond.selectedItem;
			var resultType = this.enumResult.selectedItem;
			
			var trigger:Object = {}, data:Object = Data.getInstance().dynamic_args;
			trigger.cond = {}; trigger.result = {};
			
			trigger.cond.type = condType; 
			if( data.hasOwnProperty(condType) )
				for( var key:* in data[condType] )
					trigger.cond[key] = this.condItems[key];
				
			trigger.result.type = resultType;
			if( data.hasOwnProperty(resultType) )
				for( var key:* in data[resultType] )
					trigger.result[key] = this.retItems[key];
			
			
			return trigger;
		}
	}

}