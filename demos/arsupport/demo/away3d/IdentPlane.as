package arsupport.demo.away3d
{
	import arsupport.away3d.ARAway3DContainer;

	import away3d.core.base.Vertex;
	import away3d.materials.WireColorMaterial;
	import away3d.materials.WireframeMaterial;
	import away3d.primitives.LineSegment;
	import away3d.primitives.Plane;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class IdentPlane extends ARAway3DContainer
	{
		public var world3d:Away3DWorld;
		
		public function IdentPlane(world3d:Away3DWorld, w:int, h:int)
		{
			super();
			
			this.world3d = world3d;
			
			buildModel(w, h);
		}
		
		private function buildModel(w:int = 550, h:int = 440):void
		{
			var mat:WireframeMaterial = new WireframeMaterial(0x00FF00);
			var plane:Plane = new Plane({material:mat, width:w, height:h});
			plane.rotationX = -90;

			var mat2:WireframeMaterial = new WireframeMaterial(0xFF0000);
			var mat3:WireframeMaterial = new WireframeMaterial(0x00FF00);
			var mat4:WireframeMaterial = new WireframeMaterial(0x0000FF);
			mat2.thickness = mat3.thickness = mat4.thickness = 4;
			
			var st:Vertex = new Vertex(0, 0, 0);
			var xen:Vertex = new Vertex(h*0.5, 0, 0);
			var yen:Vertex = new Vertex(0, h*0.5, 0);
			var zen:Vertex = new Vertex(0, 0, h*0.5);
			
			var lx:LineSegment = new LineSegment({material:mat2});
			var ly:LineSegment = new LineSegment({material:mat3});
			var lz:LineSegment = new LineSegment({material:mat4});
			
			lx.start = ly.start = lz.start = st;
			lx.end = xen;
			ly.end = yen;
			lz.end = zen;
			
			this.addChild( plane );
			
			addChild(lx);
			addChild(ly);
			addChild(lz);
		}
	}
}
