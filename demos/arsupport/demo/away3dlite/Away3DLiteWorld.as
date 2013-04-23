package arsupport.demo.away3dlite 
{
	import arsupport.away3dlite.ARAway3DLiteCamera;
	import arsupport.away3dlite.ARAway3DLiteContainer;
	import away3dlite.containers.Scene3D;
	import away3dlite.containers.View3D;
	import flash.display.Sprite;
	import flash.events.Event;
	import ru.inspirit.asfeat.calibration.IntrinsicParameters;

	/**
	 * @author Eugene Zatepyakin
	 */
	public final class Away3DLiteWorld extends Sprite 
	{
		public var view3d:View3D;
		public var camera3d:ARAway3DLiteCamera;
		public var scene3d:Scene3D;
		
		public var in2ar:In2ArLogo;
		public var markerPlane:MarkerPlane;
		
		public var obj3d:Vector.<ARAway3DLiteContainer>;
        
		public function Away3DLiteWorld(intrinsic:IntrinsicParameters, viewportW:int = 640, viewportH:int = 480, scale:Number = 1.0)
		{
			scene3d = new Scene3D();
			camera3d = new ARAway3DLiteCamera( intrinsic, scale );
			view3d = new View3D(scene3d, camera3d);

			view3d.x = viewportW * 0.5;
			view3d.y = viewportH * 0.5;
			view3d.z = 0;
            
            this.addChild(view3d);
			
			obj3d = new Vector.<ARAway3DLiteContainer>();
		}

        public function updateAROptions():void
        {
            camera3d.updateProjectionMatrix();
        }
		
		public function initIn2ArLogo():void
		{
			in2ar = new In2ArLogo(this);
			obj3d.push(in2ar);
            scene3d.addChild(in2ar);
		}
		
		
		public function initPlane(w:int = 550, h:int = 440):void
		{
			var plane:CoordPlane = new CoordPlane(this, w, h);
			obj3d.push(plane);
            scene3d.addChild(plane);
		}
		public function initMarkerPlane(w:int = 550, h:int = 440):void
		{
			var plane:MarkerPlane = new MarkerPlane(this, w, h);
			markerPlane = plane;
			obj3d.push(plane);
			scene3d.addChild(plane);
		}

		public function render(e:Event = null):void
		{	
			view3d.render();
		}
	}
}
