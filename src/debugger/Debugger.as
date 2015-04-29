package debugger
{
	public class Debugger
	{
		public function Debugger()
		{
		}
		
		static public function log(...args):void
		{
			trace.apply(null, args);
		}
	}
}