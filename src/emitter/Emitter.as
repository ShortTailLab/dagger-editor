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
	
	import spark.utils.BitmapUtil;
	
	public class Emitter extends Sprite
	{
		[Embed(source="assets/emitter.png")] 
		public static const ICON_EMITTER:Class;
		
		private var mImage:Bitmap;
		private var mImageBox:Sprite;
		private var mData:Object;
		private var mPanel:EmitterPanel;
		
		private var mBullets:Vector.<Bullet>;
		
		private var mWait:Number;
		private var mElapsed:Number;
		private var mInterval:Number;
		
		private var mPosX:Number;
		private var mPosY:Number;
		
		private var mVelX:Number;
		private var mVelY:Number;
		
		private var mScale:Number;
		
		private var mRotation:Number;
		private var mRotationSpeed:Number;
		
		public function Emitter() {
			this.buttonMode = true;
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function setData(data:Object, panel:EmitterPanel):void {
			mData = data;
			mPanel = panel;
			
			this.reset();
		}
		
		public function reset():void {
			if (mBullets) {
				for (var i:int = 0; i < mBullets.length; i++) {
					this.parent.removeChild(mBullets[i]);
				}
				mBullets = null;
			}
			this.alpha = 1;
			
			mBullets = new Vector.<Bullet>();
			
			mWait = 0;
			mElapsed = 0;
			mInterval = mData.interval;
			
			mPosX = mData.x;
			mPosY = mData.y;

			mRotationSpeed = mData.rotateSpeed;
			mRotation = mData.rotation;
			
			mVelX = mData.speedX + mData.speed * -Math.sin(mRotation/180*Math.PI);
			mVelY = mData.speedY + mData.speed * -Math.cos(mRotation/180*Math.PI);
			
			mScale = mData.scale;

			this.updateImage();
			this.syncView();
		}
		
		public function get sPosX():Number { return mPosX; }
		public function get sPosY():Number { return mPosY; }
		
		public function update(dt:Number):void {
			for (var i:int = mBullets.length-1; i >= 0; i--) {
				mBullets[i].update(dt);
			}
			
			if (mWait >= mData.wait) {
				// check duration
				if (mData.duration >= 0 && mElapsed >= mData.duration) {
					this.alpha = 0.3;
					return;
				}
				mElapsed += dt;
				
				// rotation
				mRotation = mRotation + mRotationSpeed*dt;
				if(mData.rotateType == 0) // shake
				{
					if (mRotation > mData.maxRotation) {
						mRotation = mData.maxRotation-(mRotation-mData.maxRotation);
						mRotationSpeed *= -1;
					}else if (mRotation < mData.minRotation) {
						mRotation = mData.minRotation-(mRotation-mData.minRotation);
						mRotationSpeed *= -1;
					}
				}
				else if(mData.rotateType == 1) // loop
				{
					if (mRotation > mData.maxRotation) {
						mRotation = (mData.minRotation + mRotation-mData.maxRotation);
					}
					else if (mRotation < mData.minRotation) {
						mRotation = (mData.maxRotation + mRotation-mData.minRotation);
					}
				}
				
				// movement
				var radian:Number = mRotation/180*Math.PI;
				var rX:Number = -Math.sin(radian);
				var rY:Number = -Math.cos(radian);
				
				mVelX += (mData.a*rX  + mData.ax) * dt;
				mVelY += (mData.a*rY  + mData.ay) * dt;
				
				mPosX += mVelX * dt;
				mPosY += mVelY * dt;
					
				mScale = Utils.clamp(mScale + mData.scalePerSec * dt, mData.scaleMin, mData.scaleMax);
			
				this.syncView();
				
				// spawn bullets
				if (mInterval > mData.interval) 
				{
					mInterval -= mData.interval;
					this.spawnBullet();					
				}
				else 
				{
					mInterval += dt;
				}
			}
			else {
				mWait += dt;
			}
		}
		
		private function spawnBullet(): void
		{
			// shoot bullets
			var num:int = mData.num + int(Math.random()*(mData.numRandom+1));
			
			var minAngle:Number = mRotation - (num-1)*mData.bulletGap*0.5;
			for (var i:int = 0; i < num; i++) {
				
				var angle: Number = 0;
				if(mData.bulletGapType == 0) // fixed angle
					angle = minAngle + i*mData.bulletGap; 
				else if(mData.bulletGapType == 1) // random angle
					angle = mRotation + (Math.random()-0.5)*mData.bulletGap;
				
				if(mData.bullet.type == "Basic")
				{
					var basic:BasicBullet = new BasicBullet();
					basic.setData(mData, angle, this, mPanel);
					
					mBullets.push(basic);
					this.parent.addChild(basic);
				}
				else if(mData.bullet.type == "Chaser")
				{
					var chaser:ChaserBullet = new ChaserBullet();
					chaser.setData(mData, angle, this, mPanel);
					
					mBullets.push(chaser);
					this.parent.addChild(chaser);
				}
				else if(mData.bullet.type == "Pather")
				{
					var pather:PatherBullet = new PatherBullet();
					pather.setData(mData, angle, this, mPanel);
					
					mBullets.push(pather);
					this.parent.addChild(pather);
				}
			}
		}
		
		private function syncView(): void{
			this.x = mPosX;
			this.y = -mPosY;
			this.rotation = mRotation;
			this.scaleX = this.scaleY = mScale;
		}
		
		public function removeBullet(bullet:Bullet):void {
			parent.removeChild(bullet);
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

		private function useImage(image:Bitmap):void  {
			
			if(mImage)
			{
				mImage.parent.removeChild(mImage);
				mImage = null;
			}
			
			if(mImageBox)
			{
				mImageBox.parent.removeChild(mImageBox);
				mImageBox = null;
			}
			
			mImage = image;
			
			mImage.x -= mImage.width*0.5;
			mImage.y -= mImage.height*0.5;
			
			mImageBox = new Sprite;
			mImageBox.addChild(mImage);
			mImageBox.rotation = mData.resRotation;
			
			this.addChild(mImageBox);
		}
		
		private static var ERROR_IMAGE:Object = {};

		public function updateImage():void {
			if(mData.res == EmitterPanel.NULL_RES)
			{
				var image:Bitmap = new ICON_EMITTER();
				useImage(image);
			}
			else
			{
				var file:File = Data.getInstance().resolvePath("skins");
				var loader:Loader = new Loader();
				
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event):void { 
					useImage(event.currentTarget.loader.content); 
				});
				
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function onLoadError(event:IOErrorEvent):void {
					if (!ERROR_IMAGE[mData.res]) {
						ERROR_IMAGE[mData.res] = true;
						Alert.show("发射器资源"+mData.res+".png未找到，请确认资源", "图片加载错误", Alert.OK);
					}
				});
				
				loader.load(new URLRequest(file.url+"/"+mData.res+".png"));
			}
		}
		
		private function onAdded(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onMouseDown(event:MouseEvent):void {
			mPanel.previewer.selectEmitter(this);
			
			var Width:Number = EmitterPreviewer.SceneWidth;
			var Height:Number = EmitterPreviewer.SceneHeight;
			
			this.startDrag(false, new Rectangle(-Width*0.5, -Height*0.5, Width, Height));
			this.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseUp(event:MouseEvent):void {
			this.stopDrag();
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(event:MouseEvent):void {
			mData.x = mPosX = this.x;
			mData.y = mPosY = -this.y;
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