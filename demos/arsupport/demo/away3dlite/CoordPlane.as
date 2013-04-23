package arsupport.demo.away3dlite
{
	import arsupport.away3dlite.ARAway3DLiteContainer;

	import away3dlite.materials.WireColorMaterial;
	import away3dlite.materials.WireframeMaterial;
	import away3dlite.primitives.LineSegment;
	import away3dlite.primitives.Plane;

	import flash.geom.Vector3D;
	/**
	 * @author Eugene Zatepyakin
	 */
	public final class CoordPlane extends ARAway3DLiteContainer 
	{
		public var world3d:Away3DLiteWorld;
		
		public function CoordPlane(world3d:Away3DLiteWorld, w:int = 550, h:int = 440)
		{
			super();
			
			this.world3d = world3d;
			
			buildModel(w, h);
		}
		private function buildModel(w:int = 550, h:int = 440):void
		{
			var mat:WireframeMaterial = new WireframeMaterial(0x00FF00, 1);
			//var mat:WireColorMaterial = new WireColorMaterial(0x000000, 0.2, 0x00FF00, 0.8, 2);
			//var w:Number = 550;
			//var h:Number = 440;
			var plane:Plane = new Plane(mat, w, h);
			plane.rotationX = -90;


			var mat2:WireColorMaterial = new WireColorMaterial(null, 0.0, 0xFF0000, 1, 4);
			var mat3:WireColorMaterial = new WireColorMaterial(null, 0.0, 0x00FF00, 1, 4);
			var mat4:WireColorMaterial = new WireColorMaterial(null, 0.0, 0x0000FF, 1, 4);
			var st:Vector3D = new Vector3D(0, 0, 0);
			var xen:Vector3D = Vector3D.X_AXIS;
			xen.scaleBy(h*0.5);
			
			var yen:Vector3D = Vector3D.Y_AXIS;
			yen.scaleBy(h*0.5);
			
			var zen:Vector3D = Vector3D.Z_AXIS;
			zen.scaleBy(h*0.5);
			
			var lx:LineSegment = new LineSegment(mat2, st, xen);
			var ly:LineSegment = new LineSegment(mat3, st, yen);
			var lz:LineSegment = new LineSegment(mat4, st, zen);
			
			this.addChild( plane );
			
			addChild(lx);
			addChild(ly);
			addChild(lz);
		}
	}
}
