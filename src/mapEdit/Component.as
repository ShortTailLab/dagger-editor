package mapEdit
{
	// interface
	import spark.core.SpriteVisualElement;
	public class Component extends SpriteVisualElement
	{
		public function select(value:Boolean):void {}
		public function setSize( value:Number  ):void {}
		public function serialize(data:Object):void {}
		public function unserialize():Object { return{}; }
	}
}