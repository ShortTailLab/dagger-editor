package bgedit
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import net.pixelpracht.tmx.TmxLayer;
	import net.pixelpracht.tmx.TmxMap;
	import net.pixelpracht.tmx.TmxTileSet;
	
	public class TmxLayerView extends Sprite
	{
		public function TmxLayerView()
		{
		}
		
		public function init(layer:TmxLayer):void {
			_layer = layer;
			
			_tiles = new Vector.<TmxTileView>();
			var tileSet:TmxTileSet = _layer.map.getTileSet(TmxMapView.tileSetName);
			var map:TmxMap = _layer.map;
			for (var i:int = 0; i < _layer.tileGIDs.length; i++) {
				for (var j:int = 0; j < _layer.tileGIDs[i].length; j++) {
					var gid:uint = _layer.tileGIDs[i][j];
					if (gid < tileSet.firstGID) {
						continue;
					}
					var diagonal:Boolean = false;
					var flipX:Boolean = false;
					var flipY:Boolean = false;
					if (gid >= tileSet.firstGID+tileSet.numTiles) {
						diagonal = Boolean(gid & TMX_DIAGONAL_FLAG);
						flipX = Boolean(gid & TMX_HORIZONTAL_FLAG);
						flipY = Boolean(gid & TMX_VERTICAL_FLAG);
//						trace(i, j, gid.toString(2), diagonal, flipX, flipY);
						gid &= ~(TMX_HORIZONTAL_FLAG | TMX_VERTICAL_FLAG | TMX_DIAGONAL_FLAG);
					}
					var tile:TmxTileView = new TmxTileView();
					var bitmapData:BitmapData = new BitmapData(tileSet.tileWidth, tileSet.tileHeight);
					bitmapData.copyPixels(tileSet.image, new Rectangle(
						((gid-tileSet.firstGID)%tileSet.numCols)*tileSet.tileWidth, 
						((int)((gid-tileSet.firstGID)/tileSet.numCols))*tileSet.tileHeight,
						tileSet.tileWidth, 
						tileSet.tileHeight), new Point(0,0));
					tile.init(bitmapData, map.tileWidth, map.tileHeight, diagonal, flipX, flipY);
					addChild(tile);
					_tiles.push(tile);
					tile.x = ((j*map.tileWidth)/*+map.tileWidth/2*/) + (i%2==0?0:1)*map.tileWidth/2;
					tile.y = (i)*map.tileHeight/2;
//					trace("adding tile gid:"+gid+" i:"+i+" j:"+j+" x:"+tile.x+" y:"+tile.y+" ");
				}
			}
		}
		
		private var _layer:TmxLayer;
		private var _tiles:Vector.<TmxTileView>;
		
		private const TMX_HORIZONTAL_FLAG:int 	= 0x80000000;
		private const TMX_VERTICAL_FLAG:int 	= 0x40000000;
		private const TMX_DIAGONAL_FLAG:int 	= 0x20000000;
	}
}