package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filters.GlowFilter;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	
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
		
		private var mWait:Number;
		private var mElapsed:Number;
		private var mInterval:Number;
		private var mBullets:Vector.<EmitterBullet>;
		private var mSpeedX:Number;
		private var mSpeedY:Number;
		private var mRotateDirection:int;
		public function reset():void {
			if (mBullets) {
				for (var i:int = 0; i < mBullets.length; i++) {
					this.parent.removeChild(mBullets[i]);
				}
				mBullets = null;
			}
			this.alpha = 1;
			mWait = 0;
			mElapsed = 0;
			mInterval = mData.interval;
			mBullets = new Vector.<EmitterBullet>();
			mSpeedX = -mData.speed*Math.sin(mData.rotation/180*Math.PI)/2;
			mSpeedY = mData.speed*Math.cos(mData.rotation/180*Math.PI)/2;
			mRotateDirection = 1;
			this.updatePosition();
		}
		
		public function update(dt:Number):void {
			for (var i:int = mBullets.length-1; i >= 0; i--) {
				mBullets[i].update(dt);
			}
			
			if (mWait >= mData.wait) {
				// check duration
				if (mData.duration >= 0) {
					if (mElapsed >= mData.duration) {
						this.alpha = 0.3;
						return;
					}
					else {
						mElapsed += dt;
					}
				}
				
				// update self
				var newR:Number = this.rotation+mData.rotateSpeed*dt*mRotateDirection;
				if (newR > mData.maxRotation) {
					if (mData.rotateType == 0) {
						this.rotation = mData.maxRotation-(newR-mData.maxRotation);
						mRotateDirection *= -1;
					}
					else {
						this.rotation = (mData.minRotation + newR-mData.maxRotation);
					}
				}
				else if (newR < mData.minRotation) {
					if (mData.rotateType == 0) {
						this.rotation = mData.minRotation-(newR-mData.minRotation);
						mRotateDirection *= -1;
					}
					else {
						// error
					}
				}
				else {
					this.rotation = newR;
				}
				
				this.x += mSpeedX*dt;
				this.y += mSpeedY*dt;
				var aax:Number = -mData.a*Math.sin(mData.rotation/180*Math.PI)/2;
				var aay:Number = -mData.a*Math.cos(mData.rotation/180*Math.PI)/2;
				mSpeedX += (mData.ax+aax)*dt/2;
				mSpeedY -= (mData.ay+aay)*dt/2;
				
				// update bullets
				if (mInterval >= mData.interval) {
					mInterval = 0;
					// shoot bullets
					var num:int = mData.num + int(Math.random()*(mData.numRandom+1));
					var newBullets:Vector.<EmitterBullet> = new Vector.<EmitterBullet>();
					for (var i:int = 0; i < num; i++) {
						var bullet:EmitterBullet = new EmitterBullet();
						this.parent.addChild(bullet);
						mBullets.push(bullet);
						newBullets.push(bullet);
						bullet.setData(mData, this);
						if (mData.bulletGapType == 1) {
							bullet.setPosition(this.x, this.y, this.rotation+Math.random()*mData.bulletGap - mData.bulletGap/2);
						}
					}
					if (num > 0 && mData.bulletGapType == 0) {
						if (newBullets.length%2 == 0) {
							for (i = 0; i < newBullets.length; i++) {
								newBullets[i].setPosition(this.x, this.y, this.rotation+((newBullets.length/2)-1-i)*mData.bulletGap+mData.bulletGap/2);
							}
						}
						else {
							for (i = 0; i < newBullets.length; i++) {
								newBullets[i].setPosition(this.x, this.y, this.rotation+((newBullets.length-1)/2-i)*mData.bulletGap);
							}
						}
					}
				}
				else {
					mInterval += dt;
				}
			}
			else {
				mWait += dt;
			}
		}
		
		public function removeBullet(bullet:EmitterBullet):void {
			mBullets.splice(mBullets.indexOf(bullet), 1);
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
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				loader.load(new URLRequest(file.url+"/"+mData.res+".png"));
			}
			else {
				mImage = new ICON_EMITTER();
				addChild(mImage);
				mImage.x = -mImage.width/2;
				mImage.y = -mImage.height/2;
			}
		}
		
		private static var ERROR_IMAGE:Object = {};
		private function onLoadError(event:IOErrorEvent):void {
			if (!ERROR_IMAGE[mData.res]) {
				ERROR_IMAGE[mData.res] = true;
				Alert.show("发射器资源"+mData.res+".png未找到，请确认资源", "图片加载错误", Alert.OK);
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
			for (var i:int = 0; i < mBullets.length; i++) {
				this.parent.removeChild(mBullets[i]);
			}
			mBullets.length = 0;
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			this.parent.removeChild(this);
		}
	}
}