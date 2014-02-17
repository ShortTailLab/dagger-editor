package Trigger
{

	import com.hurlant.crypto.symmetric.NullPad;
	
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import mx.controls.ComboBox;
	import mx.core.UIComponent;
	
	import Trigger.TNode;
	import Trigger.TriggerEvent;
	
	import behaviorEdit.BNode;
	
	import manager.EventManager;
	
	// ActionScript file
	
	class TNode extends UIComponent
	{
		public static const WIDTH:Number = 100;
		public static const HEIGHT:Number = 70;
		public static const HOR_PADDING:Number = 30;
		public static const VER_PADDING:Number = 30;
		
		public static const BG_COLOR = 0xF0FFF0;
		
		private var cond:String = "";
		private var result:String = "";
		
		private var background:Sprite = null;
		private var enumCond:ComboBox = null;
		private var enumResult:ComboBox = null;
		
		public function TNode(_condType:String = "", _retType = "")
		{
			this.cond = _condType;
			this.result = _retType;
			
			// create frame
			background = new Sprite;
			background.graphics.clear();
			background.graphics.lineStyle(1);
			background.graphics.beginFill(TNode.BG_COLOR);
			background.graphics.drawRect(
				0, 0, TNode.WIDTH, TNode.HEIGHT
			);
			background.graphics.endFill();
			this.addChild(background);
			
			var label = new TextField;
			label.defaultTextFormat = new TextFormat(null, 24);
			label.text = "条件";
			label.selectable = false;
			label.width = label.textWidth+5;
			label.height = label.textHeight+5;
			this.addChild(label);
			label.x = background.width*0.5-label.textWidth*0.5;
			label.y = background.height*0.5-label.textHeight*0.5;
			
			// 
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
		}
		
		public function setPosition(_x:Number, _y:Number) :void
		{
			this.x = _x; this.y = _y;	
		}
		
		public function init()
		{
		}
	}

}