package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;

	public class EmitterBullet extends Sprite
	{
		private var mData:Object;
		private var mImage:Bitmap;
		private var mEmitter:Emitter;
		private var mElapsed:Number;
		
		private var mSpeed: Number;
		private var mSpeedX:Number;
		private var mSpeedY:Number;
		private var mPosX:Number;
		private var mPosY:Number;
		private var mRotation:Number;
		private var mPauseTime:Number;
		
		private var mScale:Number;
		
		public function EmitterBullet()
		{
			this.mouseEnabled = false;
			this.mouseChildren = false;
		}
		
		public function setData(data:Object, defaultRot:Number, emit:Emitter):void {
			mData = data;
			mEmitter = emit;
			mElapsed = 0;
			
			var file:File = Data.getInstance().resolvePath("skins");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.load(new URLRequest(file.url+"/"+mData.bullet.res+".png"));
			
			mSpeed  = data.bullet.speed;
			mSpeedX = data.bullet.speedX;
			mSpeedY = data.bullet.speedY;
						
			mRotation = defaultRot;
			mPosX = emit.sPosX + mData.bullet.offset * -Math.sin(mRotation/180*Math.PI);
			mPosY = emit.sPosY + mData.bullet.offset * -Math.cos(mRotation/180*Math.PI);
			
			mScale = data.bullet.scale;
			
			mPauseTime = data.bullet.pauseTime;
			
			syncView();
		}
		
		private static var ERROR_IMAGE:Object = {};
		private function onLoadError(event:IOErrorEvent):void {
			if (!ERROR_IMAGE[mData.bullet.res]) {
				ERROR_IMAGE[mData.bullet.res] = true;
				Alert.show("子弹资源"+mData.bullet.res+".png未找到，请确认资源", "图片加载错误", Alert.OK);
			}
		}
		
		private function onImageLoad(event:Event):void  {
			mImage = event.currentTarget.loader.content;
			addChild(mImage);
			if (mData.bullet.direction == 1) {
				mImage.scaleY = -1;
				mImage.x = -mImage.width/2;
				mImage.y = mImage.height/2;
			}
			else {
				mImage.x = -mImage.width/2;
				mImage.y = -mImage.height/2;
			}
		}
		
		public function setPos(x:Number, y:Number): void {
			mPosX = x;
			mPosY = y;
			syncView();
		}
		
		public function setRot(r:Number): void {
			mRotation = r;
			syncView();
		}
		
		private function syncView(): void{
			this.x = mPosX*0.5;
			this.y = -mPosY*0.5;
			this.rotation = mRotation;
			this.scaleX = this.scaleY = mScale;
		}
		
		public function update(dt:Number):void {
			if(mPauseTime > 0) {
				mPauseTime -= dt;
				return;
			}
			
			// expired
			if (mData.bullet.duration >= 0 && mElapsed >= mData.bullet.duration) {
				destroy();
				return;		
			}
			
			// out of bound
			if (this.x < -250 || this.x >= 250 || 
				this.y <= -400 || this.y >= 400) {
				destroy();
				return;
			}
				
			mElapsed += dt;
			
			//mRotation += mData.bullet.rotateSpeed*dt;
			
			mSpeed  += mData.bullet.a *dt;
			mSpeedX += mData.bullet.ax*dt;
			mSpeedY += mData.bullet.ay*dt;
			
			var velX:Number = mSpeedX + mSpeed * -Math.sin(mRotation/180*Math.PI);
			var velY:Number = mSpeedY + mSpeed * -Math.cos(mRotation/180*Math.PI);
			
			mPosX += velX*dt;
			mPosY += velY*dt;
			
			if(mData.bullet.direction == 0) // align direction with velocity
			{
				var degree:Number = Math.atan2(-velX, -velY)*180/Math.PI;
				mRotation = degree;				
			}
			
			mScale = mScale + mData.bullet.scalePerSec * dt;
			
			syncView();
		}
		
		public function destroy():void {
			mEmitter.removeBullet(this);
		}
	}
}