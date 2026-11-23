package modchart.engine.modifiers.list;

import modchart.backend.core.ModifierParameters;
import modchart.backend.core.TransformMode;
import modchart.backend.core.VisualParameters;
import modchart.backend.util.ModchartUtil;

class World extends Modifier {
    final rotation:Vector3 = new Vector3();

    public function new(pf) {
        super(pf);
        setPercent('worldScaleX', 1, -1);
        setPercent('worldScaleY', 1, -1);
        setPercent('worldScaleZ', 1, -1);
    }

    override public function render(pos:Vector3, params:ModifierParameters):Vector3 {
        final p = params.player;
        final sx = getPercent('worldScaleX', p);
        final sy = getPercent('worldScaleY', p);
        final sz = getPercent('worldScaleZ', p);
        final pitch = getPercent('worldPitch', p);
        final yaw = getPercent('worldYaw', p);
        final roll = getPercent('worldRoll', p);
        final ox = WIDTH * 0.5 + getPercent('worldOriginX', p);
        final oy = HEIGHT * 0.5 + getPercent('worldOriginY', p);
        final oz = getPercent('worldOriginZ', p);
        rotation.setTo((pos.x - ox) * sx, (pos.y - oy) * sy, (pos.z - oz) * sz);
        ModchartUtil.rotate3DVectorInto(rotation, pitch, yaw, roll, rotation);
        pos.setTo(rotation.x + ox + getPercent('worldX', p), rotation.y + oy + getPercent('worldY', p),
            rotation.z + oz + getPercent('worldZ', p));
        return pos;
    }

    override public function visuals(data:VisualParameters, params:ModifierParameters):VisualParameters {
        final p = params.player;
        data.scaleX *= getPercent('worldScaleX', p);
        data.scaleY *= getPercent('worldScaleY', p);
        data.fieldAngleX += getPercent('worldPitch', p);
        data.fieldAngleY += getPercent('worldYaw', p);
        data.fieldAngleZ += getPercent('worldRoll', p);
        return data;
    }

    override public function shouldRun(params:ModifierParameters):Bool return true;
    override public function transformMode():TransformMode return TransformMode.FIELD;
    override public function isActive(p:Int):Bool {
        return getPercent('worldScaleX', p) != 1 || getPercent('worldScaleY', p) != 1 || getPercent('worldScaleZ', p) != 1
            || getPercent('worldPitch', p) != 0 || getPercent('worldYaw', p) != 0 || getPercent('worldRoll', p) != 0
            || getPercent('worldX', p) != 0 || getPercent('worldY', p) != 0 || getPercent('worldZ', p) != 0;
    }
}
