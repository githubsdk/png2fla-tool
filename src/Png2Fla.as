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

			testBitmapData();
			
			//executeScript();
		}
		
		protected function getBitmapDataValidRect(bmd:BitmapData):Rectangle
		{
			var rect:Rectangle;
			if(bmd!=null)
			{
				rect = bmd.getColorBoundsRect(0xff000000,0xff000000, true);
			}else
			{
				rect = new Rectangle();
			}
			return rect;
		}
		
		protected function testBitmapData():void
		{
			var bmd:BitmapData = new Test()//new BitmapData(100,100,true,0x00ffffff);
			bmd.fillRect( new Rectangle(20,20,60,60), 0xffffff00);
			var bmp:Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			addChild(bmp);
			var rect:Rectangle = getBitmapDataValidRect(bmd);
			trace(rect, bmp.getRect(this));
			graphics.beginFill(0xff00ff);
			graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
			graphics.endFill();
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