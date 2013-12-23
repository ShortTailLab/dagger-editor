package
{
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	public class MatsView extends UIComponent
	{
		
		public var selected:MatSprite = null;
		
		private var mats:Array = null;
		
		private var grid_width:int = 120;
		private var grid_height:int = 150;
		
		private static var instance:MatsView = null;
		public static function getInstance():MatsView
		{
			if(!instance)
				instance = new MatsView;
			return instance;
		}
		
		public function MatsView()
		{
			mats = new Array;
			
			var data:Object = Data.getInstance().matsData;
			for(var item in data)
			{
				trace(item);
				var view:MatSprite = new MatSprite(item, 100);
				view.addEventListener(MouseEvent.CLICK, onMatClick);
				this.addChild(view);
				mats.push(view);
			}
			resize(220, 0);
		}
		
		public function onMatClick(e:MouseEvent):void
		{
			var target:MatSprite = e.target as MatSprite;
			if(selected)
			{
				selected.alpha = 1;
				selected = null;
			}
			if(target != selected)
			{
				target.alpha = 0.5;
				selected = target;
			}
		}
		
		public function resize(width:Number, height:Number):void
		{
			var cols:int = width/grid_width+1;
			for(var i:int = 0; i < mats.length; i++)
			{
				mats[i].x = 60+i%cols*grid_width;
				mats[i].y = 130+int(i/cols)*grid_height;
			}
		}
	}
}