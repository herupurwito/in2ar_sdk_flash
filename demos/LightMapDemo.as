package
{
    import arsupport.away3dlite.ARAway3DLiteContainer;
    import arsupport.demo.away3dlite.Away3DLiteWorld;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.geom.Vector3D;
    import flash.media.Camera;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuItem;
    import flash.utils.ByteArray;
    import net.hires.debug.Stats;
    import ru.inspirit.asfeat.ASFEAT;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATDetectType;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    import ru.inspirit.asfeat.IASFEAT;
    import ru.inspirit.asfeat.ILightMap;

	/**
	 * @author Eugene Zatepyakin
	 */
	[SWF(width='640',height='600',frameRate='25',backgroundColor='0xFFFFFF')]
	public final class LightMapDemo extends Sprite
	{
		// embed your data file here
		[Embed(source = '../assets/def_data.ass', mimeType='application/octet-stream')]
		private static const data_ass:Class;
		
		[Embed(source = '../assets/def_marker_500.jpg')]
		private static const ref_ass:Class;
		
		// init asfeat instance and support classes
		public var asfeat:ASFEAT;
		public var asfeatLib:IASFEAT;
		
		public var refImg:BitmapData = Bitmap(new ref_ass).bitmapData;
		
		public var lightMap:ILightMap;
		
		public var intrinsic:IntrinsicParameters;
		public var world3d:Away3DLiteWorld;
		
		// max transfromation error to accept
		public var maxTransformError:Number = 10 * 10;
		
		// different visual objects
		protected var myview:Sprite;
        public static var _txt:TextField;
        protected var camBmp:Bitmap;
        protected var _cam:Camera;
        protected var _video:Video;
        protected var _cambuff:BitmapData;
        protected var _buffer:BitmapData;
        protected var _cambuff_rect:Rectangle;
		protected var _cam_mtx:Matrix;
		protected var _buff_rect:Rectangle;
		protected var _buff_mtx:Matrix;
		
		// models array if u need it
		public var models:Vector.<ARAway3DLiteContainer>;
		
		// camera size
		public var camWidth:int = 640;
        public var camHeight:int = 480;
        public var downScaleRatio:Number = 1;
        public var srcWidth:int = 640; // should be the same as camera size untill downscale is used
        public var srcHeight:int = 480;
        public var maxPointsToDetect:int = 300; // max point to allow on the screen
        public var maxReferenceObjects:int = 1; // max reference objects to be used
        public var mirror:Boolean = true; // mirror camera output
        
        public var stat:Stats;
		
		public function LightMapDemo()
		{
			if(stage) onAddedToStage();
			else addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		protected function onAddedToStage(e:Event = null):void
		{
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			
			asfeat = new ASFEAT(null);
			asfeat.addEventListener( Event.INIT, init ); // wait before this event fired or it wont work
		}
		
		protected function init(e:Event = null):void
		{
			initStage();
			//
			myview = new Sprite();
            
            // DEBUG TEXT FIELD
            _txt = new TextField();
            _txt.autoSize = 'left';
            _txt.width = 300;
            _txt.x = 5;
            _txt.y = 480;                   
            myview.addChild(_txt);
			//
			srcWidth = camWidth * downScaleRatio;
			srcHeight = camHeight * downScaleRatio;
            
            // WEB CAMERA INITIATION
            initCamera(camWidth, camHeight, 25);
            camBmp = new Bitmap(_cambuff.clone());
            myview.addChild(camBmp);
            //
            
			// DIFFERENT OBJECTS USED TO WORK WITH WEB CAMERA 
			_cambuff_rect = _cambuff.rect;
			_cam_mtx = new Matrix(-1.0, 0, 0, 1.0, camWidth);
			
			_buffer = new BitmapData( srcWidth, srcHeight, false, 0x00 );
			_buff_rect = _buffer.rect;
			_buff_mtx = new Matrix(downScaleRatio, 0, 0, downScaleRatio);
			//
			
			// INITIATE ASFEAT/IN2AR LIB
			initASFEAT();
			
			// ADD STATISTIC
			stat = new Stats();
			myview.addChild( stat );
			stat.x = 640 - 80;
			stat.y = 490;
			
			addChild(myview);
			
			// INIT 3D WORLD OBJECT
			init3d();
			
			// START DECTION + 3D RENDER
			addEventListener(Event.ENTER_FRAME, render);
		}
		
		protected function initASFEAT():void
		{
			asfeat.removeEventListener( Event.INIT, init );
			asfeatLib = asfeat.lib;
			
			// get LightMap class instance
			lightMap = asfeatLib.getLightMapInstance();
			// we downscale reference image because 
			// in real life we will never detect it
			// at original size on the screen
			var sampWidth:int = refImg.width / 3;
			var sampHeight:int = refImg.height / 3;
			
			// init our engine
			asfeatLib.init( srcWidth, srcHeight, maxPointsToDetect, maxReferenceObjects, maxTransformError, stage );
            
            // indexing reference data will result in huge
            // speed up during matching (see docs for more info)
            // !!! u always need to setup indexing even if u dont plan to use it !!!
            asfeatLib.setupIndexing(12, 10, true);
            
            // but u can switch it off if u want
            asfeatLib.setUseLSHDictionary(true);
			
			// init LightMap
			lightMap.setup(128);
			lightMap.init(refImg, sampWidth, sampHeight, 8, 6);
			
			// add reference object
			asfeatLib.addReferenceObject( ByteArray( new data_ass ) );
			
			// add event listeners
			asfeatLib.addListener( ASFEATDetectionEvent.DETECTED, onModelDetected );
			
			// limit the amount of references to be detected per frame
            // if u have only one reference u can skip this option
			asfeatLib.setMaxReferencesPerFrame(1);
		}
		
		protected function render(e:Event = null):void
		{	
			// draw video stream to buffer
			_cambuff.draw( _video );
			
			// update out screen camera bitmap
			if(mirror)
			{
				camBmp.bitmapData.draw( _cambuff, _cam_mtx );
			} else {
				camBmp.bitmapData.draw( _cambuff );
			}
			
			camBmp.bitmapData.copyPixels( lightMap.mapBitmapData, lightMap.mapRect, new Point( 640-128, 0 ) );
			
			// call it each frame so if lost will accur
			// more then 5 frames with no detected/tracked event
			// it will be erased from the screen
			models[0].lost();
			_txt.text = '';

			// update detection buffer & run detection
			_buffer.draw( _cambuff, _buff_mtx, null, null, null, true );
			asfeatLib.detect( _buffer );
			
			// render 3d world models
			world3d.render();
		}
		
		protected function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			var normal:Vector3D;
			var col:Vector.<Number> = new Vector.<Number>(3);
			
			for(var i:int = 0; i < n; ++i)
			{
				ref = refList[i];
				state = ref.detectType;
                
                world3d.markerPlane.setTransform( ref.rotationMatrix, ref.translationVector, ref.poseError, mirror );
                
                // update light map
                // care about precision
                // update only when fully visible and trackable
                
                normal = world3d.markerPlane.getSurfaceNormal();
                
                var tl_x:Number = ref.TLx;
                var tl_y:Number = ref.TLy;
                var tr_x:Number = ref.TRx;
                var tr_y:Number = ref.TRy;
                var bl_x:Number = ref.BLx;
                var bl_y:Number = ref.BLy;
                var br_x:Number = ref.BRx;
                var br_y:Number = ref.BRy;
                if (state == "_track" 
                    && tl_x > 0 && tl_x < camWidth && tr_x > 0 && tr_x < camWidth
                    && bl_x > 0 && bl_x < camWidth && br_x > 0 && br_x < camWidth
                    && tl_y > 0 && tl_y < camHeight && tr_y > 0 && tr_y < camHeight
                    && bl_y > 0 && bl_y < camHeight && br_y > 0 && br_y < camHeight)
                {
                    lightMap.addNormal(_cambuff, normal,
                                        tl_x, tl_y, tr_x, tr_y, 
                                        br_x, br_y, bl_x, bl_y);
                }
                lightMap.getNormalColor(normal, col);
                world3d.markerPlane.updateLight(col[0], col[1], col[2]);
                
                _txt.text = state;
                if(state == '_detect')
                {
                    _txt.appendText( '\nmathed: ' + ref.matchedPointsCount );
                }
                _txt.appendText( '\nfound id: ' + ref.id );
			}			
			
			_txt.appendText( '\ncalib fx/fy: ' + [intrinsic.fx, intrinsic.fy] );
		}
		
		protected function init3d():void
		{
			intrinsic = asfeatLib.getIntrinsicParams();
			world3d = new Away3DLiteWorld( intrinsic, camWidth, camHeight );
            
			world3d.initMarkerPlane(refImg.width, refImg.height);
            world3d.markerPlane.initShader();
			
			models = Vector.<ARAway3DLiteContainer>([
												world3d.markerPlane
												]);
			
			addChild(world3d);
		}
		
		protected function initCamera(w:int = 640, h:int = 480, fps:int = 25):void
        {
            _cambuff = new BitmapData( w, h, false, 0x0 );
            _cam = Camera.getCamera();
            _cam.setMode( w, h, fps, true );
            
            _video = new Video( _cam.width, _cam.height );
            _video.attachCamera( _cam );
        }
        
        protected function initStage():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			//stage.align = StageAlign.TOP_LEFT;

			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.hideBuiltInItems();

			var copyr:ContextMenuItem;
			copyr = new ContextMenuItem("ASFEAT/IN2AR DEMO", true, false);
			myContextMenu.customItems.push(copyr);
			copyr = new ContextMenuItem("© inspirit.ru", false, false);
			myContextMenu.customItems.push(copyr);

			contextMenu = myContextMenu;
		}
	}
}
