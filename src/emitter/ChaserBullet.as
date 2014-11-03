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
	
	import spark.components.Panel;

	public class ChaserBullet extends Bullet
	{
		private var mData:Object;
		private var mImageBox:Sprite;
		private var mEmitter:Emitter;
		private var mElapsed:Number;
		
		private var mSpeed: Number;
		private var mSpeedX:Number;
		private var mSpeedY:Number;
		private var mPosX:Number = 0;
		private var mPosY:Number = 0;
		private var mRotation:Number;
		private var mPauseTime:Number;
		private var mResRotation:Number;
		
		private var mFollow:Boolean = true;
		
		private var mScale:Number;
		private var mBulletConfig:Panel = null;
		
		private var mPanel:EmitterPanel = null;
		
		public function ChaserBullet()
		{
			this.mouseEnabled = false;
			this.mouseChildren = false;
		}
		
		public function setData(data:Object, defaultRot:Number, emit:Emitter, panel:EmitterPanel):void {
			mData = data;
			mPanel = panel;
			mEmitter = emit;
			mElapsed = 0;
			
			var file:File = Data.getInstance().resolvePath("skins");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.load(new URLRequest(file.url+"/"+mData.bullet.res+".png"));
			
			mPauseTime = mData.bullet.pauseTime;
			mScale = mData.bullet.scale;
			mResRotation = mData.bullet.resRotation;
			
			mSpeed  = data.bullet.speed;
			mSpeedX = data.bullet.speedX;
			mSpeedY = data.bullet.speedY;
			
			mRotation = defaultRot;
			
			mPosX = emit.sPosX + mData.bullet.offset * -Math.sin(mRotation/180*Math.PI);
			mPosY = emit.sPosY + mData.bullet.offset * -Math.cos(mRotation/180*Math.PI);
			
			// readjust rotation to face target
			if(mData.bullet.faceTarget)
			{
				var hero:HeroMarker = mPanel.getHero();
				var dx:Number = hero.posX;
				var dy:Number = hero.posY;				
				mRotation = Math.atan2(-dx, -dy)/Math.PI*180;
			}

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
			
			var image:Bitmap = event.currentTarget.loader.content;
			
			image.x -= image.width*0.5;
			image.y -= image.height*0.5;
			
			mImageBox = new Sprite;
			mImageBox.addChild(image);
			mImageBox.rotation = mResRotation;
			
			this.addChild(mImageBox);
		}
		
		public function setPos(x:Number, y:Number): void {
			mPosX = x;
			mPosY = y;
			syncView();
		}
		
		private function syncView(): void{
			this.x = mPosX*0.5;
			this.y = -mPosY*0.5;
			this.rotation = mRotation;
			this.scaleX = this.scaleY = mScale;
		}
		
		override public function update(dt:Number):void {
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

			var hero:HeroMarker = mPanel.getHero();
			if(mFollow)
			{
				var dx:Number = hero.posX - mPosX;
				var dy:Number = hero.posY - mPosY;				
				var targetAngle:Number = Math.atan2(-dx, -dy)/Math.PI*180;
				
				var diffAngle:Number = targetAngle - mRotation;
				if(diffAngle > 180)
					diffAngle -= 360;
				if(diffAngle < -180)
					diffAngle += 360;
				var deltaAngle:Number = Math.abs(mData.bullet.rotateSpeed)*dt;
				deltaAngle = Utils.clamp(deltaAngle, 0, Math.abs(diffAngle));
				mRotation +=  (diffAngle>0 ? deltaAngle : -deltaAngle);
			}
			
			if(mData.bullet.doNotTurn &&  mPosY < hero.posY)
				mFollow = false;
			
			mSpeed  += mData.bullet.a *dt;
			mSpeedX += mData.bullet.ax*dt;
			mSpeedY += mData.bullet.ay*dt;
			
			var velX:Number = mSpeedX + mSpeed * -Math.sin(mRotation/180*Math.PI);
			var velY:Number = mSpeedY + mSpeed * -Math.cos(mRotation/180*Math.PI);
			
			var speedNorm:Number = Math.sqrt(velX*velX + velY*velY);
			var clampedSpeedNorm:Number = Utils.clamp(speedNorm, mData.bullet.speedMin, mData.bullet.speedMax);
			if(clampedSpeedNorm != speedNorm)
			{
				var adjustScale:Number = clampedSpeedNorm / speedNorm;
				velX = velX * adjustScale;
				velY = velY * adjustScale;
			}
			
			mPosX += velX*dt;
			mPosY += velY*dt;
			
			if(mData.bullet.direction == 0) // align direction with velocity
			{
				var degree:Number = Math.atan2(-velX, -velY)*180/Math.PI;
				mRotation = degree;				
			}
			
			mScale = Utils.clamp(mScale + mData.bullet.scalePerSec * dt, mData.bullet.scaleMin, mData.bullet.scaleMax);
			
			syncView();
		}
		
		private function getTargetFacingAngle(): Number {
			
			var hero:HeroMarker = mPanel.getHero();
			var dx:Number = hero.posX - mPosX;
			var dy:Number = hero.posY - mPosY;				
			var targetAngle:Number = Math.atan2(-dx, -dy)/Math.PI*180;
			
			return targetAngle;
		}
		
		override public function destroy():void {
			mEmitter.removeBullet(this);
		}
	}
}