package behaviorEdit
{
	import mx.core.UIComponent;
	
	public class BTEditView extends UIComponent
	{
		public var panel:BTEditPanel = null;
		
		public function BTEditView(_panel:BTEditPanel)
		{
			panel = _panel; 
			
			var root:RootBNode = new RootBNode;
			root.x = 50;
			root.y = 50;
			root.init(this);
			
		}
	}
}