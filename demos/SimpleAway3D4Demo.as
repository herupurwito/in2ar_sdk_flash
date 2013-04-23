package  
{
    import arsupport.away3d4.ARAway3D4Container;
    import arsupport.away3d4.Away3D4Lens;
    import arsupport.demo.away3d4.In2ArLogo;
    import away3d.cameras.Camera3D;
    import away3d.containers.Scene3D;
    import away3d.containers.View3D;
    import away3d.debug.AwayStats;
    import away3d.textures.BitmapTexture;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Matrix;
    import flash.geom.Vector3D;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;
    import ru.inspirit.asfeat.ASFEAT;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    import ru.inspirit.asfeat.IASFEAT;
	
	
	
	
	/**
	 * @author Eugene Zatepyakin
	 */
	[SWF(width='1024',height='768',frameRate='25',backgroundColor='0xFFFFFF')]
	public final class SimpleAway3D4Demo extends Sprite 
	{
		// tracking data file
		[Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
		public static const DefinitionaData:Class;
		
		//asfeat variables
		private var asfeat:ASFEAT;
		private var asfeatLib:IASFEAT;
		private var intrinsic:IntrinsicParameters;
		private var maxTransformError:Number = 10 * 10;
		private var maxPointsToDetect:int = 300; // max point to allow on the screen
		private var maxReferenceObjects:int = 1; // max reference objects to be used
		
		//engine variables
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var awayStats:AwayStats;
		
		
		// different visual objects
        public static var text:TextField;
        private var video:Video;
		private var cameraBuffer:BitmapData;
		private var backgroundTexture:BitmapTexture;
		private var buffer:BitmapData;
		private var cameraMatrix:Matrix;
		
		// 3d stuff
		private var asFeatLens:Away3D4Lens;
		private var model:ARAway3D4Container;
		
	
		// camera size
		public var camWidth:int = 1024;
        public var camHeight:int = 1024;
        public var srcWidth:int = 640;
        public var srcHeight:int = 480;
        
		
		public function SimpleAway3D4Demo() 
		{
			asfeat = new ASFEAT(null);
			asfeat.addEventListener(Event.INIT, init); // wait before this event fired or it wont work
            
            mouseChildren = false;
            mouseEnabled = false;
		}
		
		private function init(e:Event = null):void
		{
            initCamera();
			initASFEAT();
			initEngine();
			initText();
			initObjects();
			initListeners();
		}
		
		private function initCamera():void
		{
			var camera:Camera = Camera.getCamera();
			camera.setMode(srcWidth, srcHeight, 25, true);
			
			video = new Video(camera.width, camera.height);
			video.attachCamera(camera);
			
			cameraMatrix = new Matrix(-camWidth/srcWidth, 0, 0, camHeight/srcHeight, camWidth);
			
			buffer = new BitmapData(srcWidth, srcHeight, false, 0x00);
			cameraBuffer = new BitmapData(camWidth, camHeight, false, 0x0);
		}
		
		private function initASFEAT():void
		{
			asfeat.removeEventListener( Event.INIT, init );
			asfeatLib = asfeat.lib;
			
			// init our engine
            asfeatLib.init( srcWidth, srcHeight, maxPointsToDetect, maxReferenceObjects, maxTransformError, stage );
            
            // indexing reference data will result in huge
            // speed up during matching (see docs for more info)
            // !!! u always need to setup indexing even if u dont plan to use it !!!
            asfeatLib.setupIndexing(12, 10, true);
            
            // but u can switch it off if u want
            asfeatLib.setUseLSHDictionary(true);
			
			// add reference object
			asfeatLib.addReferenceObject( ByteArray( new DefinitionaData ) );
			
			// ATTENTION 
			// limit the amount of references to be detected per frame
            // if u have only one reference u can skip this option
			asfeatLib.setMaxReferencesPerFrame(1);
		}
		
		private function initEngine():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			intrinsic = asfeatLib.getIntrinsicParams();
			
			asFeatLens = new Away3D4Lens(intrinsic, srcWidth, srcHeight, 1.0);
			
			view = new View3D();
			view.camera.lens = asFeatLens;
			view.camera.position = new Vector3D();
			
			view.antiAlias = 4;
			backgroundTexture = new BitmapTexture(cameraBuffer);
			view.background = backgroundTexture;
			
			addChild(view);
			
			awayStats = new AwayStats(view);
			addChild(awayStats);
		}
		
		private function initText():void
		{
			// DEBUG TEXT FIELD
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
			text.width = 300;
			text.height = 100;
			text.selectable = false;
			text.mouseEnabled = false;
			text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
			addChild(text);
		}
		
		private function initObjects():void
		{
			model = new In2ArLogo();
			view.scene.addChild(model);
		}
		
		private function initListeners():void
		{
			asfeatLib.addListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onResize();
		}
		
		private function onEnterFrame(e:Event = null):void
		{	
			//draw video stream to detection buffer & run detection
			buffer.draw(video, null, null, null, null, true);
			asfeatLib.detect(buffer);
			
			// draw detection buffer to camera buffer and flip result
			cameraBuffer.draw(buffer, cameraMatrix);
			
			//manually invalidate background texture
			backgroundTexture.invalidateContent();
			
			// call it each frame so if lost will accur
			// more then 5 frames with no detected/tracked event
			// it will be erased from the screen
			model.lost();
			text.text = '';
			
			view.render();
		}
		
		private function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			
			for(var i:int = 0; i < n; ++i) {
				ref = refList[i];
				state = ref.detectType;
				
				model.setTransform( ref.rotationMatrix, ref.translationVector, ref.poseError, true );
				text.text = state;
				
				if(state == '_detect')
					text.appendText( '\nmatched: ' + ref.matchedPointsCount );
				
				text.appendText( '\nfound id: ' + ref.id );
			}
			
			text.appendText( '\ncalib fx/fy: ' + [intrinsic.fx, intrinsic.fy] );
		}

		
		/**
		 * stage listener for resize events
		 */
		private function onResize(event:Event = null):void
		{
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
			text.y = stage.stageHeight - text.height;
			awayStats.x = stage.stageWidth - awayStats.width;
		}
		
	}

}