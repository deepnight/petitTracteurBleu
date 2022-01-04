package en;

class Hero extends Entity {
	var ca : dn.legacy.Controller.ControllerAccess;
	var back : HSprite;
	var largeWheel : HSprite;
	var smallWheel : HSprite;
	var gyro : HSprite;
	var halos : Array<HSprite> = [];
	var turnOverAnim = 0.;
	public var winX = 0.;

	public function new(e:World.Entity_Hero) {
		super(e.cx, e.cy);
		ca = Main.ME.controller.createAccess("hero");

		spr.set("tractorBase");
		addToLayer(Const.DP_HERO);

		back = Assets.tiles.h_get("tractorBack",0, 0.5,1);
		game.scroller.add(back, Const.DP_HERO_BACK);

		largeWheel = Assets.tiles.h_get("wheelLarge",0, 0.5,0.5);
		game.scroller.add(largeWheel, Const.DP_HERO_BACK);

		smallWheel = Assets.tiles.h_get("wheelSmall",0, 0.5,0.5);
		game.scroller.add(smallWheel, Const.DP_HERO_BACK);

		for(i in 0...2) {
			var halo = Assets.tiles.h_get("halo",0, 0.5,0.5);
			halos.push(halo);
			game.scroller.add(halo, Const.DP_BG);
			halo.colorize(0xffcc00);
			halo.blendMode = Add;
			halo.rotate(i*0.9);
			halo.setScale(1.5+i*0.2);
			halo.scaleX *= i%2==0 ? -1 : 1;
			halo.setPosition(footX, footY);
		}

		gyro = Assets.tiles.h_get("tractorGyro",0, 0.5,1, spr);

		hasCartoonDistorsion = false;
		carriageWidth = 0;
	}


	override function getCarriageX(offset:Float):Float {
		return game.cart.footX + Math.cos(sprRotation) * carriageWidth * offset;
	}

	override function getCarriageY(offset:Float):Float {
		return game.cart.footY - 10 + Math.sin(sprRotation) * carriageWidth * offset;
	}

	override function dispose() {
		super.dispose();

		back.remove();
		largeWheel.remove();
		smallWheel.remove();
		for(e in halos)
			e.remove();
		halos = null;
		ca.dispose();
		ca = null;
	}

	function autoWalkS(dir:Int, t:Float) {
		this.dir = dir>0 ? 1 : -1;
		cd.setS("autoWalk",t);
	}

	// var autoActions : Array<{ weight:Float, cb:Void->Void }> = [];

	// inline function queueAutoAction(weight:Float, cb:Void->Void) {
	// 	autoActions.push({
	// 		weight: weight,
	// 		cb: cb,
	// 	});
	// }

	function jump(useBumpers:Bool) {
		var bumper : Bumper = null;
		if( useBumpers ) {
			var dh = new dn.DecisionHelper(en.Bumper.ALL);
			dh.keepOnly( e->distCase(e)<=4 );
			dh.score( e->-distCase(e) );
			bumper = dh.getBest();
		}

		setSquashX(0.6);
		cd.unset("wasOnGround");
		game.cart.onHeroJump();

		if( bumper!=null ) {
			cancelVelocities();
			dy = -0.8;
			cd.setS("bumperJump",0.2);
			cd.setS	("walkLock",0.3);
			bumper.onUse();
		}
		else {
			bdy = 0;
			dy = -0.25;
			cd.setS("extraJump",0.15);
		}
	}

	override function onLand() {
		super.onLand();
		setSquashY(0.6);
	}

	override function postUpdate() {
		super.postUpdate();

		spr.rotation = M.fclampSym( dyTotal * dir, 0.1 );

		var hDir = 1;
		for( halo in halos) {
			halo.x += ( footX-halo.x+dir*30 ) * 0.1;
			halo.y += ( footY-halo.y-20 ) * 0.1;
			halo.rotate(0.0035*tmod*hDir);
			halo.alpha = 0.03 + 0.12*game.level.clampedNightRatio;
			hDir*=-1;
		}

		// Scale anims
		var moving = getControllerX()!=0;
		var movingOnGround = onGround && moving;

		spr.scaleX *= (1-turnOverAnim*0.7);
		turnOverAnim *= Math.pow(0.8,tmod);

		var t = !isSleeping() ? ftime*0.1 : ftime*0.03;
		spr.scaleX *= 0.95 + Math.cos(t)*0.05;
		spr.scaleY *= 0.95 + Math.sin(t)*0.05;
		if( isSleeping() ) {
			spr.scaleX*=1.1;
			spr.scaleY*=0.9;
		}
		if( !movingOnGround )
			spr.y += -1 + Math.sin(t)*2;

		gyro.alpha = M.fabs( Math.cos(ftime*0.1) );

		// Wheels
		smallWheel.x = Std.int( footX + dir*9 * (1-turnOverAnim) );
		smallWheel.y = footY - 4 + ( onGround ? 0 : dyTotal>=0.05*tmod ? 2 : -1 );

		largeWheel.x = Std.int( footX - dir*6 * (1-turnOverAnim) );
		largeWheel.y = footY - 6 + ( onGround ? 0 : dyTotal>=0.05*tmod ? 2 : -1 );

		if( movingOnGround ) {
			largeWheel.y-=rnd(0,1);
			smallWheel.y-=rnd(0,1);
			spr.scaleY *= 1 + 0.05*Math.cos(ftime*0.4+uid);
			spr.y += -M.fabs( Math.sin( ftime*0.5+uid)*1 );
		}

		// Particles
		if( movingOnGround && !cd.hasSetS("grass",0.06) )
			fx.grass(footX, footY, -dir);

		if( !cd.hasSetS("smoke", moving ? 0.18 : 0.5 ) )
			fx.tractorSmoke(footX-dir*6, footY-8, -dir);

		// Tractor back shape
		back.x = spr.x+1;
		back.y = spr.y;
		back.scaleX = spr.scaleX;
		back.scaleY = spr.scaleY;
		back.rotation = spr.rotation;

		if( isSleeping() && !cd.hasSetS("zzz",0.9) )
			fx.zzz(footX-dir*0, footY-16, -dir);


		// var t = ftime*0.1 + uid;
		// smallWheel.scaleY = 0.8 + Math.sin(t)*0.2;
	}


	public inline function isSleeping() {
		return false;
	}

	public inline function controlsLocked() {
		return game.levelComplete;
	}

	function getControllerX() : Float {
		if( controlsLocked() )
			return 0;
		else if( ca.lxValue()!=0 )
			return ca.lxValue();
		else if( game.mouseDown )
			return M.fclamp(game.mouseX/game.w(), 0, 1) < 0.5 ? -1 : 1;
			// return ( M.fclamp(game.mouseX/game.w(), 0, 1) - 0.5 ) * 2;
		else
			return 0;
	}

	public function onShortPress(jumpDir:Int) {
		if( !controlsLocked() && onGroundRecently ) {
			jump(true);
			if( !cd.has("walkLock") )
				autoWalkS(jumpDir, 0.5);
		}
	}

	var cliffInsistF = 0.;
	override function update() {
		super.update();

		var spd = 0.016;

		// Jump off cliffs
		if( !onGround && onGroundRecently && getControllerX()!=0 && dyTotal>0 && !cd.hasSetS("cliffMiniJump",0.5) )
			dy = -0.11;

		// Walk
		if( getControllerX()!=0 && !cd.has("autoWalk") && !cd.has("walkLock") ) {
			dx += getControllerX() * spd * (1-0.5*cd.getRatio("slowdown")) * tmod;
			var oldDir = dir;
			dir = getControllerX()>0 ? 1 : -1;

			if( oldDir!=dir )
				turnOverAnim = 1;

			if( onGround && level.hasMark(CliffHigh,cx,cy,dir) )
				cliffInsistF += tmod;

			// Auto jumps
			if( onGround ) {
				// Climb small step
				if( level.hasMark(StepSmall, cx, cy, dir) && sightCheckCase(cx,cy) ) {
					jump(false);
					autoWalkS(level.getMarkDir(StepSmall, cx, cy), 0.3);
					xr = 0.5;
					dy*=0.45;
				}
				// Climb high step
				if( level.hasMark(StepHight, cx, cy, dir) && sightCheckCase(cx,cy) ) {
					jump(false);
					autoWalkS(level.getMarkDir(StepHight, cx, cy), 0.3);
					xr = 0.5;
				}
			}
		}
		else
			cliffInsistF = 0;

		// Auto walk
		if( cd.has("autoWalk") ) {
			dx += dir * spd * tmod;
		}

		// Brake on cliff
		if( onGround && level.hasMark(CliffHigh, cx,cy, M.sign(dxTotal)) && cliffInsistF<=0.4*Const.FPS ) {
			var cliffXr = ( 0.5 + 0.4*M.sign(dxTotal) );
			var ratio = 1-M.fabs( cliffXr - xr );
			dx *= Math.pow(0.95 - 0.85*ratio,tmod);
		}

		// Bump away from cliffs
		var cliffDir = level.getMarkDir(CliffHigh,cx,cy);
		if( onGround && level.hasMark(CliffHigh,cx,cy) && cliffInsistF<=0 && ( cliffDir==1 && xr>=0.6 || cliffDir==-1 && xr<=0.4 ) ) {
			bump(-cliffDir*0.03, -0.1);
		}

		// Edge grabbing
		if( level.hasMark(EdgeGrab,cx,cy) && !onGround && dyTotal>0 ) {
			var edgeDir = level.getMarkDir(EdgeGrab,cx,cy);
			if( dir==edgeDir && ( edgeDir==1 && xr>=0.3 || edgeDir==-1 && xr<=0.7 ) ) {
			// if( M.sign(ca.lxValue())==edgeDir ) {
				dx = edgeDir * 0.05;
				autoWalkS( edgeDir, 0.1 );
				dy = -0.3;
				xr = 0.5;
				yr = M.fmin(yr,0.4);
				bdy = 0;
			}
		}

		// Jump
		if( !controlsLocked() && ca.aPressed() && ( onGround || onGroundRecently ) ) {
			jump(true);
		}
		else if( cd.has("bumperJump") ) {
			dy += -0.10*tmod;
		}
		else if( cd.has("extraJump") ) {
			dy += -0.04*tmod;
		}

		// Level complete jumps
		if( game.levelComplete && onGround && !cd.hasSetS("happyJump",rnd(0.4,0.6)) ) {
			var jDir = Std.random(2)*2-1;
			var maxDist = Const.GRID*1;
			if( footX>winX+maxDist )
				jDir = -1;
			if( footX<winX-maxDist )
				jDir = 1;
			dx = rnd(0.1,0.2) * jDir;
			if( dir!=jDir ) {
				setSquashX(0.3);
				dir = jDir;
			}
			else
				setSquashX(0.6);
			dy = -rnd(0.2,0.25);
			game.cart.dy = -rnd(0.1,0.15);
			fx.fireworks(centerX, centerY);
			gravityMul = 0.7;
		}

		// Execute 1 auto-action
		// if( autoActions.length>0 ) {
		// 	var dh = new dn.DecisionHelper(autoActions);
		// 	dh.score( (a)->a.weight );
		// 	dh.getBest().cb();
		// 	autoActions = [];
		// }

		// Grab items
		for(e in en.Item.ALL) {
			if( e.isAlive() && !e.isCarried() && !e.cd.has("heroPickLock") ) {
				if( e.gravityMul==0 && !onGround && distCase(e)<=4 && M.fabs(cx-e.cx)<=2 )
					startCarrying(e);
				else if( distCase(e)<=2.5 )
					startCarrying(e);
			}
		}

		#if debug
		if( ca.isKeyboardPressed(K.BACKSPACE) )
			stopCarryingAnything();
		#end
	}

}