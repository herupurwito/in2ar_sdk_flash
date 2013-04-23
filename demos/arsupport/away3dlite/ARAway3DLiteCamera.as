package arsupport.away3dlite 
{
	import away3dlite.arcane;
	import away3dlite.cameras.Camera3D;
	import flash.geom.Matrix3D;
	import ru.inspirit.asfeat.calibration.IntrinsicParameters;

	use namespace arcane;

	/**
	 * @author Eugene Zatepyakin
	 */
	public final class ARAway3DLiteCamera extends Camera3D 
	{
		public const arProjectionMatrix:Matrix3D = new Matrix3D();

        protected var intrinsic:IntrinsicParameters;
		
		public function ARAway3DLiteCamera(intrinsic:IntrinsicParameters, viewportToSourceWidthRatio:Number = 1.0)
		{
			super();
			
			this.x = 0;
			this.y = 0;
			this.z = 0;

			this.intrinsic = intrinsic;
			
			updateProjectionMatrix(viewportToSourceWidthRatio);
		}

        public function updateProjectionMatrix(viewportToSourceWidthRatio:Number = 1.0):void
        {
            arProjectionMatrix.rawData = getProjectionMatrix(viewportToSourceWidthRatio);
            lens = new ARLens(arProjectionMatrix);
        }

		protected function getProjectionMatrix(ratio:Number = 1.0):Vector.<Number>
		{
			return Vector.<Number>([
					intrinsic.fx*ratio,	0,	        		0,	    0,
                    0,          		intrinsic.fy*ratio,	0,	    0,
                    0,	        		0,	        		1,	    1,
                    0,		    		0,		    		0,	    0
				]);
		}
	}
}

import away3dlite.arcane;
import away3dlite.cameras.lenses.AbstractLens;

import flash.geom.Matrix3D;

use namespace arcane;

internal final class ARLens extends AbstractLens
{
	protected var arProjectionMatrix:Matrix3D;
				
	public function ARLens (arProjectionMatrix:Matrix3D)
	{
		this.arProjectionMatrix = arProjectionMatrix;
		super();
	}
	
	arcane override function _update () :void 
	{
		_projectionMatrix3D = arProjectionMatrix;
	}
}
