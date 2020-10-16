package en;

class Cart extends Entity {
	// var trackPoints = new haxe.ds.Vector(30);
	// var trackIdx = 0;

	public function new() {
		super( hero.cx, hero.cy);

		var g = new h2d.Graphics(spr);
		g.beginFill(0x674423);
		g.drawRect(-10,-10,20,10);
		frictX = frictY = 0.94;
		gravityMul = 0.33;
	}

	override function postUpdate() {
		super.postUpdate();
	}

	override function update() {
		// trackPoints[trackIdx] = hero.makePoint();
		// trackIdx++;

		// Follow tractor
		var cartDist = 16 * ( level.hasCollision(cx,cy) ? 0.33 : 1 );
		var tx = hero.footX - hero.dir*cartDist;
		var ty = hero.footY - 3; // + ( level.hasCollision(cx,cy+1) ? 0 : 7);
		var a = Math.atan2(ty-footY, tx-footX);
		var d = M.dist(footX, footY, tx, ty);
		var spd = 0.015;
		var far = d>Const.GRID*0.7;
		hasWallCollisions = !far && !level.hasCollision(cx,cy);
		gravityMul = far ? 0 : 1;

		dx += Math.cos(a) * spd*tmod;
		dy += Math.sin(a) * spd*tmod;

		var ra = angToFeet(hero) + ( hero.footX>footX ? 0 : M.PI );
		sprRotation = ra;

		super.update();
	}
}

