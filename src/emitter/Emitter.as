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
		private var mSpeed:Number;
		private var mSpeedX:Number;
		private var mSpeedY:Number;
		
		private var mRotation:Number;
		private var mRotationSpeed:Number;
		
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
			mSpeed = mData.speed;
			mSpeedX = mData.speedX;
			mSpeedY = mData.speedY;
			
			mRotationSpeed = mData.rotateSpeed;
			mRotation = mData.rotation;

			this.updateImage();
			this.updatePosition();
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
				mSpeed  += mData.a*dt;
				mSpeedX += mData.ax*dt;
				mSpeedY += mData.ay*dt;
				
				var velX:Number = mSpeedX + mSpeed * -Math.sin(mRotation/180*Math.PI)
				var velY:Number = mSpeedY + mSpeed * -Math.cos(mRotation/180*Math.PI);
				
				mPosX += velX * dt;
				mPosY += velY * dt;
				
				// set display object
				this.rotation = mRotation;
				this.x =  mPosX*0.5;
				this.y = -mPosY*0.5;
				
				// update bullets
				
				if (mInterval > mData.interval) 
				{
					mInterval -= mData.interval;
					
					// shoot bullets
					var num:int = mData.num + int(Math.random()*(mData.numRandom+1));
						
					var minAngle:Number = mRotation - (num-1)*mData.bulletGap*0.5;
					for (var i:int = 0; i < num; i++) {
						
						var angle: Number = 0;
						if(mData.bulletGapType == 0) // fixed angle
						{
							angle = minAngle + i*mData.bulletGap; 
						}
						else if(mData.bulletGapType == 1) // random angle
						{
							angle = mRotation + (Math.random()-0.5)*mData.bulletGap;
						}
						
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
				else {
					mInterval += dt;
				}
			}
			else {
				mWait += dt;
			}
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
		
		public function updatePosition():void {
			this.x =  mData.x*0.5;
			this.y = -mData.y*0.5;
			this.rotation = mData.rotation;
		}
		
		private function onAdded(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onMouseDown(event:MouseEvent):void {
			mPanel.previewer.selectEmitter(this);
			
			var Width:int = 360;
			var Height:int = 640;
			
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
			mData.x = mPosX = this.x*2;
			mData.y = mPosY = -this.y*2;
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