package  
{
    import aerys.minko.Minko;
    import aerys.minko.render.Viewport;
    import aerys.minko.scene.node.Camera;
    import aerys.minko.scene.node.Group;
    import aerys.minko.scene.node.mesh.geometry.primitive.QuadGeometry;
    import aerys.minko.scene.node.mesh.Mesh;
    import aerys.minko.scene.node.Scene;
    import aerys.minko.type.log.DebugLevel;
    import aerys.minko.type.math.Vector4;
    import arsupport.demo.minko.Castle;
    import arsupport.demo.minko.In2ArLogo;
    import arsupport.minko.MinkoIN2ARController;
    import arsupport.minko.MinkoCameraController;
    import arsupport.minko.MinkoCaptureGeometry;
    import arsupport.minko.MinkoCaptureMesh;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageQuality;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.geom.Point;
    import flash.geom.Vector3D;
    import flash.media.Video;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;
    import ru.inspirit.asfeat.ASFEAT;
    import ru.inspirit.asfeat.calibration.IntrinsicParameters;
    import ru.inspirit.asfeat.detect.ASFEATReference;
    import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
    import ru.inspirit.asfeat.IASFEAT;
    import ru.inspirit.asfeat.ILightMap;
    
	
	/**
     * ...
     * @author Eugene Zatepyakin
     */
    [SWF(width='640', height='480', frameRate='30',backgroundColor='0xFFFFFF')]
    public final class MinkoLightMapDemo extends Sprite 
    {
        // tracking data file
		[Embed(source="../assets/def_data.ass", mimeType="application/octet-stream")]
		public static const DefinitionaData:Class;
        
        [Embed(source = '../assets/def_marker_500.jpg')]
		private static const ref_ass:Class;
        
        public var refImg:BitmapData = Bitmap(new ref_ass).bitmapData;
        
        //asfeat variables
        public var asfeat:ASFEAT;
		public var asfeatLib:IASFEAT;
        public var intrinsic:IntrinsicParameters;
        public var maxPoints:int = 300; // max points to allow to detect
        public var maxReferences:int = 5; // max objects will be used
        public var maxTrackIterations:int = 5; // track iterations
		public var lightMap:ILightMap;
		
		//engine variables
		private var scene:Scene;
		private var camera:Camera;
		private var view:Viewport;
		
		// different visual objects
        public static var text:TextField;
		
		// 3d stuff
        private var cameraController:MinkoCameraController;
        private var cameraMesh:MinkoCaptureMesh;
        private var model:In2ArLogo;
        private var controller:MinkoIN2ARController;
		
        // Capture stuff
        public var streamW:int = 640;
        public var streamH:int = 480;
        public var streamFPS:int = 30;
        
        public function MinkoLightMapDemo() 
        {
            asfeat = new ASFEAT(null);
			asfeat.addEventListener(Event.INIT, init); // wait before this event fired or it wont work
            
            mouseChildren = false;
            mouseEnabled = false;
        }
        
        private function init(e:Event = null):void
		{            
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            //stage.quality = StageQuality.LOW;
            
            initNativeCamera();
			initASFEAT();
			initEngine();
			initText();
			initObjects();
			initListeners();
		}
        
        private function initASFEAT():void
		{
            asfeat.removeEventListener(Event.INIT, init);
            asfeatLib = asfeat.lib;
			
			// init our engine
            asfeatLib.init( streamW, streamH, maxPoints, maxReferences, 100, stage );
            
            // indexing reference data will result in huge
            // speed up during matching (see docs for more info)
            // !!! u always need to setup indexing even if u dont plan to use it !!!
            asfeatLib.setupIndexing(12, 10, true);
            
            // but u can switch it off if u want
            asfeatLib.setUseLSHDictionary(true);
            
            // add image
			asfeatLib.addReferenceObject( ByteArray( new DefinitionaData ) );
			
            // ATTENTION 
			// limit the amount of references to be detected per frame
            // if u have only one reference u can skip this option
			asfeatLib.setMaxReferencesPerFrame(1);
            
            // get LightMap class instance
			lightMap = asfeatLib.getLightMapInstance();
			// we downscale reference image because 
			// in real life we will never detect it
			// at original size on the screen
			var sampWidth:int = refImg.width / 3;
			var sampHeight:int = refImg.height / 3;
            // init LightMap
			lightMap.setup(128);
			lightMap.init(refImg, sampWidth, sampHeight, 8, 6);
		}
        
        private var stageW:int = 640;
        private var stageH:int = 480;
        private function initEngine():void
		{
			intrinsic = asfeatLib.getIntrinsicParams();
            
            stageW = streamW;// stage.stageWidth;
            stageH = streamH;// stage.stageHeight;
			
            view = new Viewport(2, stageW, stageH);
            scene = new Scene();
            camera = new Camera();
            
            cameraMesh = new MinkoCaptureMesh(view.width, view.height, 
                                                streamW, streamH, 
                                                MinkoCaptureGeometry.FILL_MODE_PRESERVE_ASPECT_RATIO_AND_FILL);
            cameraMesh.setupForBitmapData(buffer);
            
            // calculate cam scale
            var sc:Number = Math.max(stageW / streamW, stageH / streamH);
            cameraController = new MinkoCameraController(intrinsic, sc);
            camera.removeAllControllers();
            camera.addController(cameraController);
            
            scene.addChild(camera);
            scene.addChild(cameraMesh);
            
            //Minko.debugLevel = DebugLevel.CONTEXT;
			
			addChild(view);
		}
		
		private function initText():void
		{
			// DEBUG TEXT FIELD
			text = new TextField();
			text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
            text.background = true;
            text.backgroundColor = 0x000000;
            text.textColor = 0xFFFFFF;
			text.width = 300;
			text.height = 18;
			text.selectable = false;
			text.mouseEnabled = false;
            text.y = stage.stageHeight - text.height;
            text.autoSize = "left";
			addChild(text);
		}
		
		private function initObjects():void
		{
            model = new In2ArLogo();
            // light map
            model.setupLightMap(lightMap.mapBitmapData);
            
            // controller
            controller = new MinkoIN2ARController(maxReferences);
            controller.addReference(0, model);
            
            scene.addChild(model);
		}
		
		private function initListeners():void
		{
            asfeatLib.addListener(ASFEATDetectionEvent.DETECTED, onModelDetected);
			asfeatLib.addListener(ASFEATDetectionEvent.FAILED, onDetectionFailed);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
        public const light_map_point:Point = new Point(640 - 128, 0);
		private function onEnterFrame(e:Event = null):void
		{
            buffer.draw(video);
            asfeatLib.detect(buffer);
            
            buffer.copyPixels(lightMap.mapBitmapData, lightMap.mapRect, light_map_point);
            
            cameraMesh.invalidate();
            controller.lost();
            scene.render(view);
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
				
				controller.setTransform( ref.id, ref.rotationMatrix, ref.translationVector, ref.poseError, false );
				text.text = state;
                text.appendText( ' @ ' + ref.id );
				
				if(state == '_detect')
					text.appendText( ' :: matched: ' + ref.matchedPointsCount );
                    
                // update light map
                // care about precision
                // update only when fully visible and trackable
                var tl_x:Number = ref.TLx;
                var tl_y:Number = ref.TLy;
                var tr_x:Number = ref.TRx;
                var tr_y:Number = ref.TRy;
                var bl_x:Number = ref.BLx;
                var bl_y:Number = ref.BLy;
                var br_x:Number = ref.BRx;
                var br_y:Number = ref.BRy;
                if (state == "_track" 
                    && tl_x > 0 && tl_x < streamW && tr_x > 0 && tr_x < streamW
                    && bl_x > 0 && bl_x < streamW && br_x > 0 && br_x < streamW
                    && tl_y > 0 && tl_y < streamH && tr_y > 0 && tr_y < streamH
                    && bl_y > 0 && bl_y < streamH && br_y > 0 && br_y < streamH)
                {
                    var normal:Vector3D = model.getSurfaceNormal();
                    lightMap.addNormal(buffer, normal,
                                        tl_x, tl_y, tr_x, tr_y, 
                                        br_x, br_y, bl_x, bl_y);
                    
                    lightMap.invalidate();
                    model.updateLightMap();
                }
			}
		}
        
        private function onDetectionFailed(e:ASFEATDetectionEvent):void 
        {
            text.text = "nothing found";
        }
        
        private var video:Video;
        private var buffer:BitmapData;
        private function initNativeCamera():void
		{
			var camera:flash.media.Camera = flash.media.Camera.getCamera();
			camera.setMode(streamW, streamH, streamFPS, false);
			
			video = new Video(camera.width, camera.height);
			video.attachCamera(camera);
			
			buffer = new BitmapData(streamW, streamH, false, 0x00);
		}
        
    }

}