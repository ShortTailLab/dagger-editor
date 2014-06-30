package emitter
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLRequest;

	public class EmitterBullet extends Sprite
	{
		private var mData:Object;
		private var mImage:Bitmap;
		private var mEmitter:Emitter;
		private var mElapsed:Number;
		private var mSpeedX:Number;
		private var mSpeedY:Number;
		
		public function EmitterBullet()
		{
			this.mouseEnabled = false;
			this.mouseChildren = false;
		}
		
		public function setData(data:Object, emit:Emitter):void {
			mData = data;
			mEmitter = emit;
			mElapsed = 0;
			
			var file:File = Data.getInstance().resolvePath("skins");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad);
			loader.load(new URLRequest(file.url+"/"+mData.bullet.res+".png"));
		}
		
		public function setPosition(xv:Number, yv:Number, r:Number):void {
			this.x = xv;
			this.y = yv;
			this.rotation = r;
			mSpeedX = -mData.bullet.speed*Math.sin(rotation/180*Math.PI)/2;
			mSpeedY = mData.bullet.speed*Math.cos(rotation/180*Math.PI)/2;
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
		
		public function update(dt:Number):void {
			if (mData.bullet.duration > 0) {
				if (mElapsed >= mData.bullet.duration) {
					destroy();
				}
				else {
					mElapsed += dt;
				}
			}
			else {
				if (this.x < -250 || this.x >= 250 || this.y <= -400 || this.y >= 400) {
					destroy();
				}
			}
			this.x += mSpeedX*dt;
			this.y += mSpeedY*dt;
			var aax:Number = -mData.bullet.a*Math.sin(this.rotation/180*Math.PI)/2;
			var aay:Number = -mData.bullet.a*Math.cos(this.rotation/180*Math.PI)/2;
			mSpeedX += (mData.bullet.ax+aax)*dt/2;
			mSpeedY -= (mData.bullet.ay+aay)*dt/2;
			if (mSpeedX == 0) {
				if (mSpeedY > 0) this.rotation = 0;
				else if (mSpeedY < 0) this.rotation = 180;
			}
			else {
				var degree:Number = Math.atan2(mSpeedY, mSpeedX)*180/Math.PI-90;
				this.rotation = degree;
			}
		}
		
		public function destroy():void {
			mEmitter.removeBullet(this);
			parent.removeChild(this);
		}
	}
}