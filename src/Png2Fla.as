package
{
	import flash.display.Sprite;
	import flash.filesystem.File;
	
	public class Png2Fla extends Sprite
	{
		public function Png2Fla()
		{
			executeScript();
		}
		
		protected function executeScript():void
		{
			var path:String = "assets/export_feed_png.jsfl";
			path = "assets/icon.png"
			var file:File = File.applicationDirectory.resolvePath(path);
			trace(file.url);
			file.openWithDefaultApplication();
		}
	}
}