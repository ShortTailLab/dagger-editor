package emitter
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	public class EmitterPreviewer extends Sprite
	{
		private var mData:Object;
		private var mElapsedTf:TextField;
		private var mElapsed:Number;
		private var mEmitters:Vector.<Emitter>;
		private var mContainer:Sprite;
		private var mPanel:EmitterPanel;
		
		public function EmitterPreviewer(data:Object, panel:EmitterPanel) {
			mData = data;
			mPanel = panel;
			
			var menu:ContextMenu = new ContextMenu();
			var item:ContextMenuItem = new ContextMenuItem("复制(Ctrl+C)");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onCopyEmitter);
			menu.addItem(item);
			item = new ContextMenuItem("删除(Ctrl+D)");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onDeleteEmitter);
			menu.addItem(item);
			item = new ContextMenuItem("粘贴(Ctrl+V)");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onPasteEmitter);
			menu.addItem(item);
			item = new ContextMenuItem("剪切(Ctrl+X)");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onCutEmitter);
			menu.addItem(item);
			this.contextMenu = menu;
			
			init();
			restart();
		}
		
		private function onCopyEmitter(event:Event):void {
			mPanel.onCopyEmitter(event);
		}
		
		private function onDeleteEmitter(event:Event):void {
			mPanel.onDeleteEmitter(event);
		}
		
		private function onPasteEmitter(event:Event):void {
			mPanel.onPasteEmitter(event);
		}
		
		private function onCutEmitter(event:Event):void {
			mPanel.onCutEmitter(event);
		}
		
		private function init():void {
			var s:Sprite = new Sprite();
			this.addChild(s);
			s.graphics.lineStyle(1, 0xAAAAAA);
			s.graphics.moveTo(0,0);
			s.graphics.lineTo(400, 0);;
			s.graphics.moveTo(0,0);
			s.graphics.lineTo(0, -640);
			
			for (var i:int = 0; i <= 400; i+=50) {
				s.graphics.moveTo(i,0);
				s.graphics.lineTo(i, 10);
				var tf:TextField = new TextField();
				tf.mouseEnabled = false;
				tf.text = (i*2-400).toString();
				s.addChild(tf);
				tf.x = i-(i==200?0:10);
				tf.y = 15;
			}
			
			for (i = 0; i <= 640; i+=40) {
				s.graphics.moveTo(0,-i);
				s.graphics.lineTo(-10, -i);
				tf = new TextField();
				tf.mouseEnabled = false;
				tf.text = (i*2-640).toString();
				s.addChild(tf);
				tf.x = -35;
				tf.y = -i-8;
			}
			
			s.graphics.beginFill(0xEEEEEE);
			s.graphics.drawRect(0, -640, 400, 640);
			s.graphics.endFill();
			s.graphics.moveTo(190, -320);
			s.graphics.lineTo(210, -320);
			s.graphics.moveTo(200, -310);
			s.graphics.lineTo(200, -330);
			
			tf = new TextField();
			tf.mouseEnabled = false;
			tf.text = "已启动时间：";
			s.addChild(tf);
			tf.x = 0; tf.y = -680;		
			
			mElapsedTf = new TextField();
			mElapsedTf.mouseEnabled = false;
			mElapsedTf.text = "0.0s";
			s.addChild(mElapsedTf);
			mElapsedTf.x = 70; mElapsedTf.y = -680;
			
			mContainer = new Sprite();
			addChild(mContainer);
			mContainer.x = 200; mContainer.y = -320;
			
			mEmitters = new Vector.<Emitter>();
			for (var i:int = 0; i < mData.emitters.length; i++) {
				var emit:Emitter = new Emitter();
				mContainer.addChild(emit);
				emit.setData(mData.emitters[i], this.mPanel);
				mEmitters.push(emit);
			}
		}
		
		public function restart():void {
			mElapsed = 0;
			for (var i:int = 0; i < mEmitters.length; i++) {
				mEmitters[i].reset();
			}
			
			if (!hasEventListener(Event.ENTER_FRAME)) {
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		private static const DELTA:Number = 1/30;
		private function onEnterFrame(event:Event):void {
			mElapsed += DELTA;
			this.mElapsedTf.text = mElapsed.toFixed(2)+"s";
			for (var i:int = 0; i < mEmitters.length; i++) {
				mEmitters[i].update(DELTA);
			}
		}
		
		public function addEmitter(data:Object):void {
			var emit:Emitter = new Emitter();
			mContainer.addChild(emit);
			emit.setData(data, this.mPanel);
			mEmitters.push(emit);
		}
		
		public function removeEmitter(index:int):void {
			mEmitters[index].destroy();
			mEmitters.splice(index, 1);
		}
		
		// from emitter
		public function selectEmitter(emit:Emitter):void {
			var index:int = mEmitters.indexOf(emit);
			for (var i:int = 0; i < mEmitters.length; i++) {
				mEmitters[i].setSelected(i == index);
			}
			mPanel.setSelectedEmitter(index);
		}
		
		// from panel
		public function selectIndex(index:int):void {
			for (var i:int = 0; i < mEmitters.length; i++) {
				mEmitters[i].setSelected(i == index);
			}
		}
		
		public function destroy():void {
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			parent.removeChild(this);
		}
		
		public function get emitters():Vector.<Emitter> { return mEmitters; }
	}
}