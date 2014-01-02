package
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.core.UIComponent;
	
	public class FormationsView extends UIComponent
	{
		private var formsNum:int = 0;
		
		public function FormationsView()
		{
			for(var name in Formation.getInstance().formations)
			{
				add(name);
			}
			
			Formation.getInstance().addEventListener(MsgEvent.ADD_FORMATION, onAdd);
		}
		
		private function onAdd(e:MsgEvent):void
		{
			add(e.hintMsg);
		}
		
		private function add(name:String):void
		{
			var logo:FormationSprite = new FormationSprite(name);
			var pos:Point = Utils.makeGrid(new Point(10, 100), 100, 2, formsNum++);
			logo.x = pos.x;
			logo.y = pos.y;
			logo.trim(50)
			addChild(logo);
		}
	}
}