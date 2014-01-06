package bgedit
{
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	
	import spark.components.BorderContainer;
	import spark.components.HGroup;
	import spark.components.VGroup;

	public class BgEditView extends HGroup
	{
		public function BgEditView()
		{			
			initToolBar();
			initAxis();
			initContainer();
		}
		
		private function initToolBar():void {
			var toolVGroup:VGroup = new VGroup();
			
			var borderContainer:BorderContainer;
			var vgroup:VGroup;
			var button:Button;
			
			borderContainer = new BorderContainer();
			vgroup = new VGroup();
			vgroup.paddingLeft = 5;
			vgroup.paddingRight = 5;
			vgroup.paddingTop = 5;
			vgroup.paddingBottom = 5;
			button = new Button();
			button.label = "Hand";
			button.toolTip = "抓手工具";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "+";
			button.toolTip = "放大";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "-";
			button.toolTip = "缩小";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			borderContainer.addElement(vgroup);
			toolVGroup.addElement(borderContainer);
			
			borderContainer = new BorderContainer();
			vgroup = new VGroup();
			vgroup.paddingLeft = 5;
			vgroup.paddingRight = 5;
			vgroup.paddingTop = 5;
			vgroup.paddingBottom = 5;
			button = new Button();
			button.label = "VL";
			button.toolTip = "垂直左对齐";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "VC";
			button.toolTip = "垂直居中";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "VR";
			button.toolTip = "垂直右对齐";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			borderContainer.addElement(vgroup);
			toolVGroup.addElement(borderContainer);
			
			borderContainer = new BorderContainer();
			vgroup = new VGroup();
			vgroup.paddingLeft = 5;
			vgroup.paddingRight = 5;
			vgroup.paddingTop = 5;
			vgroup.paddingBottom = 5;
			button = new Button();
			button.label = "HL";
			button.toolTip = "水平左对齐";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "HC";
			button.toolTip = "水平居中";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			button = new Button();
			button.label = "HR";
			button.toolTip = "水平右对齐";
			button.width = 50;
			button.addEventListener(MouseEvent.CLICK, onClickTool);
			vgroup.addElement(button);
			borderContainer.addElement(vgroup);
			toolVGroup.addElement(borderContainer);
			
			addElement(toolVGroup);
		}
		
		private function onClickTool(event:MouseEvent):void {
			switch ((event.currentTarget as Button).label) {
				case "Hand": 
					this.buttonMode = !this.buttonMode;
					break;
				case "+": break;
				case "-": break;
				case "VL": break;
				case "VC": break;
				case "VR": break;
				case "HL": break;
				case "HC": break;
				case "HR": break;
			}
		}
		
		private function initAxis():void {
			
		}
		
		private function initContainer():void {
			_tmxMapView = new TmxMapView();
			addElement(_tmxMapView);
			_tmxMapView.load("Resource/bg.tmx", 
				function():void {
					trace("tmx inited",_tmxMapView.tmxMap.totalHeight, _tmxMapView.tmxMap.totalWidth); 
				}
			);
		}
		
		public function get tmxMapView():TmxMapView {
			return _tmxMapView;
		}
		
		private var _tmxMapView:TmxMapView;
	}
}