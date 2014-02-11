package manager
{
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Sequence;
	import mx.events.EffectEvent;
	
	import spark.components.Group;
	import spark.components.Panel;
	import spark.effects.Fade;

	public class MsgInform
	{
		static private var _instance:MsgInform;
		static public function shared():MsgInform
		{
			if(!_instance)
				_instance = new MsgInform;
			return _instance;
		}
		
		public function MsgInform()
		{
		}
		
		public function show(par:Panel, msg:String):void
		{
			var pos:Point = new Point(par.width*0.5, par.height*0.5);
			var msgContainer:UIComponent = new UIComponent;
			var label:TextField = new TextField;
			label.defaultTextFormat = new TextFormat(null, 26, 0xff0000);
			label.text = msg;
			label.width = label.textWidth+10;
			label.height = label.textHeight+10;
			label.x = -label.textWidth*0.5;
			label.y = -label.textHeight*0.5;
			msgContainer.x = par.width*0.5;
			msgContainer.y = par.height*0.5+50;
			msgContainer.addChild(label);
			par.addElement(msgContainer);
			
			var seq:Sequence = new Sequence;
			var move:Move = new Move(msgContainer);
			move.xFrom = pos.x;
			move.yFrom = pos.y+100;
			move.xTo = pos.x;
			move.yTo = pos.y;
			move.duration = 400;
			seq.addChild(move);
			
			var fade:Fade = new Fade(msgContainer);
			fade.alphaFrom = 1;
			fade.alphaTo = 0;
			fade.duration = 500;
			fade.addEventListener(EffectEvent.EFFECT_END, onMoveEnd);
			seq.addChild(fade);
			
			seq.play();
		}
		
		private function onMoveEnd(e:EffectEvent):void
		{
			var label:UIComponent = (e.target as Fade).target as UIComponent;
			if(label)
				Group(label.parent).removeElement(label);
			
		}
	}
}