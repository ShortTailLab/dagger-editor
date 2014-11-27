package emitter
{
	import flash.display.Sprite;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import misc.SceneGrid;
	
	import spark.components.Label;
	
	public class EmitterPreviewer extends Sprite
	{
		private var mData:Object;
		private var mElapsedTf:TextField;
		private var mElapsed:Number;
		private var mEmitters:Vector.<Emitter>;
		private var mContainer:Sprite;
		private var mPanel:EmitterPanel;
		
		private var mHero:HeroMarker = null;
		
		public static const SceneWidth:Number = 720;
		public static const SceneHeight:Number = 1280;
		
		public static const ScenePadding:Number = 200;
		
		public static const SceneCenter:Point = new Point(SceneWidth*0.5, SceneHeight*0.5);
		
		public static const SceneBound:Rectangle = new Rectangle(-ScenePadding, -ScenePadding, 
			SceneWidth+ScenePadding*2, SceneHeight+ScenePadding*2);
		
		public function EmitterPreviewer(data:Object, panel:EmitterPanel) {
			mData = data;
			mPanel = panel;
			
			var menu:ContextMenu = new ContextMenu();
			var item:ContextMenuItem = new ContextMenuItem("新建(Ctrl+N)");
			item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, onNewEmitter);
			menu.addItem(item);
			item = new ContextMenuItem("复制(Ctrl+C)");
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
		
		private function onNewEmitter(event:Event):void {
			mPanel.onNewEmitter(event);
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

			var grid:SceneGrid = new SceneGrid(SceneWidth, SceneHeight, false);
			this.addChild(grid);
			
			mElapsedTf = new TextField();
			mElapsedTf.mouseEnabled = false;
			mElapsedTf.text = "启动时间: 0.0s";
			mElapsedTf.x = 70; 
			mElapsedTf.y = -SceneHeight-30;
			mElapsedTf.scaleX = mElapsedTf.scaleY = 2;
			grid.addChild(mElapsedTf);
			
			mContainer = new Sprite();
			mContainer.x = SceneWidth*0.5; 
			mContainer.y = -SceneHeight*0.5;
			this.addChild(mContainer);
			
			mEmitters = new Vector.<Emitter>();
			for (var i:int = 0; i < mData.emitters.length; i++) {
				var emit:Emitter = new Emitter();
				emit.setData(mData.emitters[i], mPanel);
				mEmitters.push(emit);
				mContainer.addChild(emit);
			}
			
			mHero = new HeroMarker();
			mHero.setData({x: 0, y:-400}, mPanel);
			mContainer.addChild(mHero);
			
			this.scaleX = this.scaleY = 0.5;
		}
		
		public function getHero(): HeroMarker
		{
			return mHero;
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
			this.mElapsedTf.text = "启动时间:" + mElapsed.toFixed(2) + "s";
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