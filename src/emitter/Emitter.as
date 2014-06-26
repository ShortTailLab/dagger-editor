package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	public class Emitter extends Sprite
	{
		[Embed(source="assets/emitter.png")] 
		public static const ICON_EMITTER:Class;
		
		private var mImage:Bitmap;
		private var mData:Object;
		private var mPanel:EmitterPanel;
		
		public function Emitter() {
			this.buttonMode = true;
			
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function setData(data:Object, panel:EmitterPanel):void {
			mData = data;
			mPanel = panel;
			
			updateImage();
			updatePosition();
		}
		
		public function update(dt:Number):void {
			
		}
		
		public function setSelected(bool:Boolean):void {
			if (bool) {
				var filter:GlowFilter = new GlowFilter();
				filter.color = 0xFFFF00;
				filter.strength = 10;
				this.filters = [filter];
			}
			else {
				this.filters = [];
			}
		}
		
		public function updateImage():void {
			if (mImage) {
				removeChild(mImage);
				mImage = null;
			}
			if (mData.res != EmitterPanel.NULL_RES) {
				var file:File = Data.getInstance().resolvePath("skins");
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
				loader.load(new URLRequest(file.url+"/"+mData.res+".png"));
			}
			else {
				mImage = new ICON_EMITTER();
				addChild(mImage);
				mImage.x = -mImage.width/2;
				mImage.y = -mImage.height/2;
			}
		}
		
		public function updatePosition():void {
			this.x = mData.x/2;
			this.y = -mData.y/2;
			this.rotation = mData.rotation;
		}
		
		private function onImageLoad(event:Event):void  {
			mImage = event.currentTarget.loader.content;
			addChild(mImage);
			mImage.x = -mImage.width/2;
			mImage.y = -mImage.height/2;
		}
		
		private function onAdded(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onMouseDown(event:MouseEvent):void {
			mPanel.previewer.selectEmitter(this);
			this.startDrag(false, new Rectangle(-200, -320, 400, 640));
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseUp(event:MouseEvent):void {
			this.stopDrag();
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(event:MouseEvent):void {
			mData.x = this.x*2;
			mData.y = -this.y*2;
			mPanel.updateCurrentEmitter();
		}
		
		public function destroy():void {
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
	}
}