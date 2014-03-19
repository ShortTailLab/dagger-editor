package tools
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.TitleWindow;
	
	public class RenamePanel extends TitleWindow
	{
		private var mInputField:TextInput;
		private var mConfirmButton:Button;
		
		public function RenamePanel(onComplete:Function)
		{
			var self:RenamePanel = this;
			with( this ) {
				title = "重命名"; width = 200; height = 150;
			}
			
			this.mInputField = new TextInput;
			with( this.mInputField ) { 
				x = 10; y = 10; height 30; width = 150; 
			}
			this.addElement(mInputField);
			
			this.mConfirmButton = new Button;
			with( this.mConfirmButton ) {
				label = "确定"; x = 10; y = 50;  
			}
			this.mConfirmButton.addEventListener( MouseEvent.CLICK, 
				function( e:MouseEvent ) :void {
					onComplete(mInputField.text);
					PopUpManager.removePopUp(self);
				}
			);
			this.addElement( this.mConfirmButton );
			
			this.addEventListener(CloseEvent.CLOSE, 
				function():void {
					onComplete(null);
					PopUpManager.removePopUp(self);
				}
			);
			
			PopUpManager.addPopUp( this, this, true );
			PopUpManager.centerPopUp( this );
		}
	}
}