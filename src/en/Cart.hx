package en;

class Cart extends Entity {
	var link : h2d.Graphics;
	var smallWheel : HSprite;

	public function new() {
		super( hero.cx, hero.cy);

		frictX = frictY = 0.95;
		gravityMul = 0.33;
		hasCartoonDistorsion = false;

		link = new h2d.Graphics();
		game.scroller.add(link, Const.DP_UI);

		smallWheel = Assets.tiles.h_get("wheelSmall",0, 0.5,0.5);
		game.scroller.add(smallWheel, Const.DP_MAIN);

		spr.set("cart");
		spr.setCenterRatio(0.5,0.5);
		addToLayer(Const.DP_MAIN);
	}

	override function dispose() {
		super.dispose();
		smallWheel.remove();
		link.remove();
	}

	override function postUpdate() {
		super.postUpdate();

		spr.y-=5;
		smallWheel.x = Std.int( footX );
		smallWheel.y = Std.int( footY-4 );

		// Ground bumps
		if( M.fabs(hero.dxTotal)>=0.03 && yr>=0.7 && level.hasCollision(cx,cy+1) && !cd.hasSetS("bump",0.3) )
			cd.setS("bumping",rnd(0.1,0.2));
		if( cd.has("bumping") )
			spr.y-= Math.sin( (1-cd.getRatio("bumping")) * M.PI )*3.5;

		// Wheel shakes
		if( M.fabs(dxTotal)>=0.03 )
			smallWheel.y -= rnd(0,1);

		// Link render
		link.clear();
		link.lineStyle(2,0x695039);
		var fx = hero.footX-hero.dir*10;
		var fy = hero.footY-7;
		link.moveTo(fx,fy);
		var tx = footX + dirTo(hero)*9;
		var ty = footY-6;
		var d = distPx(hero);
		var tension = M.fclamp( (distPx(hero)-20)/18, 0, 1 );
		link.curveTo(
			(fx+tx)*0.5,
			(fy+ty)*0.5 + 10 * (1-tension),
			tx,
			ty
		);
	}

	override function update() {
		// Follow tractor
		var cartDist = 20 * ( level.hasCollision(cx,cy) ? 0.33 : 1 );
		var tx = hero.footX - hero.dir*cartDist;
		var ty = hero.footY - 3;
		if( level.hasCollision(cx,cy) && !level.hasCollision(cx,cy-1) )
			ty = cy*Const.GRID;
		var a = Math.atan2(ty-footY, tx-footX);
		var d = M.dist(footX, footY, tx, ty);

		var needRecal = d>Const.GRID*1.2 || /*M.fabs(ty-footY)>=Const.GRID*0.8 || */ level.hasCollision(cx,cy);
		var spd = needRecal ? 0.024 : 0.013;
		// hasWallCollisions = !needRecal;
		gravityMul = needRecal ? 0 : 1;
		debug(needRecal);

		fx.markerFree(footX,footY, 0.1, 0x00ff00);
		fx.markerFree(tx,ty, 0.1, 0x0088ff);

		dx += Math.cos(a) * spd*tmod;
		dy += Math.sin(a) * spd*tmod;

		if( !needRecal ) {
			dx*=Math.pow(0.89,tmod);
			dy*=Math.pow(0.94,tmod);
		}

		super.update();

		// Relocate out of collisions
		if( level.hasCollision(cx,cy) ) {
			var dh = new dn.DecisionHelper( dn.Bresenham.getDisc(cx,cy,2) );
			dh.keepOnly( pt->!level.hasCollision(pt.x,pt.y) );
			dh.keepOnly( pt->hero.sightCheckCase(pt.x, pt.y) );
			dh.score( pt->level.hasCollision(pt.x,pt.y+1) ? 0.5 : 0 );
			dh.score( pt->-distCaseFree(pt.x,pt.y)*0.3 );
			dh.useBest( pt->{
				var tx = (pt.x+0.5) * Const.GRID;
				var ty = (pt.y+0.5) * Const.GRID;
				var a = Math.atan2(footY-ty, footX-tx);
				fx.markerCase(pt.x,pt.y, 0xffcc00);
				setPosPixel(
					tx + Math.cos(a)*Const.GRID*0.5,
					ty + Math.sin(a)*Const.GRID*0.5
				);
			});
		}
	}

	override function fixedUpdate() {
		super.fixedUpdate();

		var ra = 0.95 * ( hero.footX>footX ? angToFeet(hero) : hero.angToFeet(this) );
		sprRotation += ( ra - sprRotation ) * 0.35;
	}
}

