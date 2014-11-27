package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.net.URLRequest;
	
	import mx.controls.Alert;
	import mx.utils.ObjectUtil;
	
	import spark.components.Panel;

	public class PatherBullet extends Bullet
	{
		private var mData:Object;
		private var mImageBox:Sprite;
		private var mEmitter:Emitter;
		private var mElapsed:Number;
		
		private var mSpeed: Number;
		private var mPosX:Number;
		private var mPosY:Number;
		private var mRotation:Number;
		private var mPauseTime:Number;
		private var mResRotation:Number;
		
		private var mInitialPosX:Number;
		private var mInitialPosY:Number;
		
		private var mScale:Number;
		private var mBulletConfig:Panel = null;
		
		private var mPanel:EmitterPanel = null;
		
		private var mPointIndex:int = 0;
		
		public function PatherBullet()
		{
			this.mouseEnabled = false;
			this.mouseChildren = false;
		}
		
		public function setData(data:Object, defaultRot:Number, emit:Emitter, panel:EmitterPanel):void {
			mData = data;
			mEmitter = emit;
			mElapsed = 0;
			
			var file:File = Data.getInstance().resolvePath("skins");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			loader.load(new URLRequest(file.url+"/"+mData.bullet.res+".png"));
			
			mSpeed  = data.bullet.speed;
						
			mRotation = defaultRot;
			
			
			if(data.bullet.path.points.length > 0)
			{
				if(data.bullet.path.isRelative)
				{
					mPosX = emit.sPosX; 
					mPosY = emit.sPosY;
				}
				else
				{
					mPosX = data.bullet.path.points[mPointIndex].x; 
					mPosY = data.bullet.path.points[mPointIndex].y;
				}
				mPointIndex++;
			}
			else
			{
				mPosX = emit.sPosX; 
				mPosY = emit.sPosY;	
			}
			
			mInitialPosX = mPosX;
			mInitialPosY = mPosY;
			 
			mScale = data.bullet.scale;
			
			mPauseTime = data.bullet.pauseTime;
			
			mPanel = panel;
			mResRotation = mData.bullet.resRotation;
			
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
			this.x = mPosX;
			this.y = -mPosY;
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
			
			var center:Point = EmitterPreviewer.SceneCenter; 
			if(!EmitterPreviewer.SceneBound.contains(mPosX+center.x, mPosY+center.y))
			{
				destroy();
				return;
			}
			
			if(mData.bullet.path.isLoop && mPointIndex >= mData.bullet.path.points.length)
			{
				mPointIndex = 0;
			}
			
			var dirX:Number = 0;
			var dirY:Number = 0;
			var target:Object = null;
			
			// no more waypoints
			if(mPointIndex >= mData.bullet.path.points.length)
			{
				dirX = -Math.sin(mRotation/180*Math.PI);
				dirY = -Math.cos(mRotation/180*Math.PI);
			}
			else
			{
				target = ObjectUtil.copy(mData.bullet.path.points[mPointIndex]);
				if(mData.bullet.path.isRelative)
				{
					target.x += (mInitialPosX - mData.bullet.path.points[0].x);
					target.y += (mInitialPosY - mData.bullet.path.points[0].y);
				}
				dirX = target.x - mPosX;
				dirY = target.y - mPosY;
				var dirNorm:Number = Math.sqrt(dirX*dirX + dirY*dirY);
				dirX = dirX / dirNorm;
				dirY = dirY / dirNorm;
			}
			
			mElapsed += dt;
			
			mSpeed  += mData.bullet.a *dt;
			mSpeed = Utils.clamp(mSpeed, mData.bullet.speedMin, mData.bullet.speedMax);
			
			var velX:Number = mSpeed * dirX;
			var velY:Number = mSpeed * dirY;
			
			// pass through, do not turn around and chase
			if(target && (Math.pow(velX*dt, 2) + Math.pow(velY*dt, 2) > Math.pow(dirNorm, 2)))
			{
				mPosX = target.x;
				mPosY = target.y;
			}
			else
			{
				mPosX += velX*dt;
				mPosY += velY*dt;				
			}			

			if(target)
			{
				var dist2:Number = Math.pow(target.x-mPosX, 2) + Math.pow(target.y-mPosY, 2);
				if(dist2 < 2*2)
					mPointIndex++;
			}
			
			if(mData.bullet.direction == 0) // align direction with velocity
			{
				var degree:Number = Math.atan2(-velX, -velY)*180/Math.PI;
				mRotation = degree;
			}
				
			mScale = Utils.clamp(mScale + mData.bullet.scalePerSec * dt, mData.bullet.scaleMin, mData.bullet.scaleMax);
			
			syncView();
		}
		
		override public function destroy():void {
			mEmitter.removeBullet(this);
		}
	}
}