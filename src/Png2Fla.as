package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	
	public class Png2Fla extends Sprite
	{
		public function Png2Fla()
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.color = 0x0099ff;
			var bmd:BitmapData = new Test();
			var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			addChild(bmp);
			var rect:Rectangle = bmd.getColorBoundsRect(0xff000000,0xff000000, true);
			//rect = bmd.getColorBoundsRect(0xff000000, 0x00000000,true);
			trace(rect, bmp.getRect(this));
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
			
			return;
			rect = bmd.getColorBoundsRect(0xff000000, 0x00000000);
			graphics.beginFill(0xff0000);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
			
			trace(rect);
			//executeScript();
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