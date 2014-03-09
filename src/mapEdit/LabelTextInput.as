package mapEdit
{
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.TextInput;
	
	public class LabelTextInput extends HGroup
	{
		public var label:spark.components.Label = null;
		public var textInput:TextInput = null;
		
		public function LabelTextInput(title:String)
		{
			super();
			
			label = new Label;
			label.text = title;
			this.addElement(label);
			
			textInput = new TextInput();
			this.addElement(textInput);
		}
	}
}