package  
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.filters.BlurFilter;
	import flash.filters.DisplacementMapFilter;
	import flash.filters.DisplacementMapFilterMode;
	import flash.geom.Point;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.Loader;
	import flash.net.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.getQualifiedClassName;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import mx.controls.SWFLoader;
		
	[SWF(width="940", height="680", backgroundColor="0xffffff", frameRate="30")]
	public class Top extends Sprite
	{
		// 定数
		private const STOP_SEC:Number = 12; // 静止時間（秒）
		private const FRAME_RATE:int = 30; // フレームレート
		private const THRESHOLD:Number = 0.005; // 閾値
		private const URLS:Array = [
						 "http://www.hairs-anchor.com/images/top/01.png",
						 "http://www.hairs-anchor.com/images/top/02.png"
					 ];
		// 変数
		[Embed(source='images/loading.png')]
		private var LoadingClass:Class;
		private var loadingImage:Bitmap;
		private var fadeInTimer:Timer;
		private var fadeOutTimer:Timer;
		private var stopTimer:Timer;
		private var _center:Point;
		private var noiseBitmapData:BitmapData;
		private var image:Bitmap;
		private var scale:Number = 1;
		private var initialTime:int;
		private var initialY:int;
		private var stopFlag:Boolean = false;
		private var loadedCount:int = 0;
		private var loaders:Array = new Array();
		private var currentIndex:int = 0;

		public function Top()
		{
			//Security.loadPolicyFile("http://www.hairs-anchor.com/crossdomain.xml");
			_center = new Point(stage.stageWidth * 0.5, stage.stageHeight * 0.5);
			// Loading...
			loadingImage = new LoadingClass();
			loadingImage.x = _center.x - (loadingImage.width * 0.5);
			loadingImage.y = _center.y - (loadingImage.height * 0.5);
			loadingImage.visible = true;
			addChild(loadingImage);
			addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public function init():void {
			stage.addEventListener(Event.RESIZE, resizeHandler);
			for(var i:int; i<URLS.length; i++){
				var l:Loader = new Loader();
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadHandler);
				l.load(new URLRequest(URLS[i]), new LoaderContext(true));
			}
			fadeInTimer  = new Timer(1000 / FRAME_RATE);
			stopTimer    = new Timer(STOP_SEC * 1000);
			fadeOutTimer = new Timer(1000 / FRAME_RATE);
			
			fadeInTimer.addEventListener(TimerEvent.TIMER, timerFadeInHandler);
			fadeOutTimer.addEventListener(TimerEvent.TIMER, timerFadeOutHandler);
			stopTimer.addEventListener(TimerEvent.TIMER, stopTimerHandler);
		}

		private function resizeHandler(e:Event):void 
		{
			_center.x = stage.stageWidth * 0.5;
			_center.y = stage.stageHeight * 0.5;
		}
		
		private function onLoadHandler(e:Event):void 
		{
			loaders.push(e.target.loader);
			loadedCount++;
			if(loadedCount >= URLS.length){
				currentIndex = 0;
				onLoadedAllImageHandler(currentIndex);
			}
		}

		private function onLoadedAllImageHandler(index:int):void 
		{
			loadingImage.visible = false;
			image = loaders[index].content as Bitmap;

			image.x = _center.x - image.width * 0.5;
			image.y = _center.y - image.height * 0.5;
			
			noiseBitmapData = image.bitmapData.clone();
			var seed:Number = Math.random();
			var offsets:Array = [new Point(0,0)];
			noiseBitmapData.perlinNoise(40, 50, 1, seed, false, true, 1, false, offsets);
			image.visible = false;
			addChild(image);

			fadeInTimer.start();
			initialTime = getTimer();
			initialY = image.y;
		}
		
		/**
		 * フェードイン
		 **/
		private function timerFadeInHandler(e:TimerEvent):void 
		{
			var factor:Number = (Math.cos((getTimer() - initialTime)/900) + 1) * 0.4;
			if(!stopFlag && factor < THRESHOLD){
				image.filters = null;
				fadeInTimer.stop();
				stopFlag = true;
				stopTimer.start();
			}
			if(!stopFlag){
				scale = 300 * factor;
				image.alpha = 1 - factor;
				var df:DisplacementMapFilter = new DisplacementMapFilter(noiseBitmapData, new Point(), 1, 1, 10, scale, DisplacementMapFilterMode.CLAMP, 0, 0);
				var blurSize:Number = 40 * factor;
				var bf:BlurFilter = new BlurFilter(blurSize, blurSize);
				image.filters = [df, bf];
				image.y = initialY + factor * 100;
			}
			image.visible = true;
		}

		/**
		 * 停止
		 **/
		private function stopTimerHandler(e:TimerEvent):void 
		{
			stopFlag = false;
			stopTimer.stop();
			fadeOutTimer.start();
			initialTime = getTimer();
		}

		/**
		 * フェードアウト
		 **/
		private function timerFadeOutHandler(e:TimerEvent):void {
			var factor:Number = (Math.sin((getTimer() - initialTime)/900) + 1) * 0.5;
			if(!stopFlag && factor > 1 - THRESHOLD){
				image.filters = null;
				fadeOutTimer.stop();
				// 画像の入れ替え
				removeChild(image);
				if(currentIndex == (URLS.length - 1)){
					currentIndex = 0;
				}else{
					currentIndex++;
				}
				onLoadedAllImageHandler(currentIndex);
				stopFlag = false;
				fadeInTimer.start();
				initialTime = getTimer();
			}
			if(!stopFlag){
				scale = 300 * factor;
				image.alpha = 1 - factor;
				var df:DisplacementMapFilter = new DisplacementMapFilter(noiseBitmapData, new Point(), 1, 1, 10, scale, DisplacementMapFilterMode.CLAMP, 0, 0);
				var blurSize:Number = 40 * factor;
				var bf:BlurFilter = new BlurFilter(blurSize, blurSize);
				image.filters = [df, bf];
				image.y = initialY + factor * 100;
			}
		}
		
		private function addedToStage(e:Event):void 
		{
			removeEventListener(e.type, arguments.callee);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			init();	
		}
		
		public function get center():Point {
			return _center;
		}
	}
}
