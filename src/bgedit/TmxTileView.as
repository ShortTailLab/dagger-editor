package bgedit
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public class TmxTileView extends Sprite
	{
		public function TmxTileView()
		{
			
		}
		
		public function init(bitmapData:BitmapData, w:Number, h:Number, diagonal:Boolean, flipX:Boolean, flipY:Boolean):void {
			var bitmap:Bitmap = new Bitmap(bitmapData);
			addChild(bitmap);
			bitmap.x = -bitmapData.width/2;
			bitmap.y = -bitmapData.height/2;
			if (diagonal) {
				if (flipX && flipY) {
					this.rotation = 270;
					this.scaleY = -this.scaleY;
				}
				else if (flipX) {
					this.rotation = 90;
				}
				else if (flipY) {
					this.rotation = 270;
				}
				else {
					this.rotation = 90;
					this.scaleY = -this.scaleY;
				}
			}
			else {
				if (flipX) {
					this.scaleX = -this.scaleX;
				}
				if (flipY) {
					this.scaleY = -this.scaleY;
				}
			}
			
//			bitmap.x -= (bitmapData.width/2-w/2);
//			bitmap.y -= (bitmapData.height/2-h/2);
		}
	}
}