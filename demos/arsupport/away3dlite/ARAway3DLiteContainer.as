package arsupport.away3dlite 
{
	import away3dlite.containers.ObjectContainer3D;

	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	/**
	 * @author Eugene Zatepyakin
	 */
	public class ARAway3DLiteContainer extends ObjectContainer3D
	{		
		public var maxLostCount:int = 5;
		public var lostCount:int = 0;
		public var detected:Boolean = false;

        public var surfNormal:Vector3D = new Vector3D(0, 0, 0, 1.0);
		
		protected var nextData:Vector.<Number> = new Vector.<Number>(16, true);
		public var nextMatrix:Matrix3D = new Matrix3D();
		
		public function ARAway3DLiteContainer()
		{
			super();
			visible = false;
		}
		
		public function setTransform(R:Vector.<Number>, t:Vector.<Number>, matrixError:Number, mirror:Boolean = false):void
		{
            if (++lostCount < 0) return;
            
			getAway3DLiteMatrix( nextData, R, t, mirror );
			nextMatrix.rawData = nextData;
			//this.transform.matrix3D.rawData = nextData;
			this.transform.matrix3D.interpolateTo( nextMatrix, 0.75 );
			
			visible = true;
			detected = true;
			lostCount = 0;
		}
		
		public function lost():void
		{
			if(visible && ++lostCount == maxLostCount)
			{
				hideObject();
			}
		}
		
		public function hideObject(e:Event = null):void
		{
			this.transform.matrix3D.identity();
            visible = false;
			detected = false;
            lostCount = -maxLostCount;
		}

        public function getSurfaceNormal():Vector3D
        {
            //var dt:Vector.<Number> = this.transform.matrix3D.rawData;

            //surfNormal.x = dt[2];
            //surfNormal.y = dt[6];
            //surfNormal.z = dt[10];
			
            surfNormal.x = 0;
            surfNormal.y = 0;
            surfNormal.z = -1;
            surfNormal = this.transform.matrix3D.deltaTransformVector(surfNormal);

            surfNormal.normalize();

            return surfNormal;
        }
		
		public function getAway3DLiteMatrix(data:Vector.<Number>, R:Vector.<Number>, t:Vector.<Number>, mirror:Boolean = false):void
		{

			if(!mirror)
			{
				data[0] = -R[0];	data[1] = -R[3];	data[2] = -R[6];	data[3] = 0.0;
				data[4] = R[1];		data[5] = R[4];		data[6] = R[7];		data[7] = 0.0;
				data[8] = -R[2];	data[9] = -R[5];	data[10] = -R[8];	data[11] = 0.0;
				data[12] = t[0];	data[13] = t[1];	data[14] = t[2];	data[15] = 1.0;
			}
			else
			{
				data[0] = -R[0];	data[1] = R[3];		data[2] = R[6];		data[3] = 0.0;
				data[4] = -R[1];	data[5] = R[4];		data[6] = R[7];		data[7] = 0.0;
				data[8] = R[2];		data[9] = -R[5];	data[10] = -R[8];	data[11] = 0.0;
				data[12] = -t[0];	data[13] = t[1];	data[14] = t[2];	data[15] = 1.0;
			}
		}
	}
}
