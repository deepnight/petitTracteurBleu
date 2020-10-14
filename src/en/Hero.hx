package en;

class Hero extends Entity {
	var ca : dn.heaps.Controller.ControllerAccess;

	public function new(e:World.Entity_Hero) {
		super(e.cx, e.cy);
		ca = Main.ME.controller.createAccess("hero");
	}

	override function dispose() {
		super.dispose();

		ca.dispose();
		ca = null;
	}

	function autoWalkS(dir:Int, t:Float) {
		this.dir = dir>0 ? 1 : -1;
		cd.setS("autoWalk",t);
	}

	var autoActions : Array<{ weight:Float, cb:Void->Void }> = [];

	inline function queueAutoAction(weight:Float, cb:Void->Void) {
		autoActions.push({
			weight: weight,
			cb: cb,
		});
	}

	function jump() {
		bdy = 0;
		dy = -0.2;
		cd.setS("extraJump",0.15);
	}

	var cliffInsistF = 0.;
	override function update() {
		super.update();

		var spd = 0.016;

		// Walk
		if( ca.leftDist()>0 && !cd.has("autoWalk") ) {
			dx += Math.cos( ca.leftAngle() ) * spd * tmod;
			dir = M.radDistance( ca.leftAngle(), 0 ) <= M.PIHALF ? 1 : -1;
			if( onGround && level.hasMark(CliffHigh,cx,cy,dir) )
				cliffInsistF += tmod;

			// Auto jumps
			if( onGround ) {
				// Climb small step
				if( level.hasMark(StepSmall, cx, cy, dir) && sightCheckCase(cx,cy) ) {
					var stepDir = level.getMarkDir(StepSmall, cx, cy);
					queueAutoAction( (M.sign(dir)==M.sign(stepDir) ? 2 : 0 ), ()->{
						jump();
						autoWalkS(stepDir, 0.3);
						xr = 0.5;
						dy*=0.5;
					});
				}
				// Climb high step
				if( level.hasMark(StepHight, cx, cy, dir) && sightCheckCase(cx,cy) ) {
					var stepDir = level.getMarkDir(StepHight, cx, cy);
					queueAutoAction( (M.sign(dir)==M.sign(stepDir) ? 2 : 0 ), ()->{
						jump();
						autoWalkS(stepDir, 0.3);
						xr = 0.5;
					});
				}
			}
		}
		else
			cliffInsistF = 0;

		debug( M.pretty(cliffInsistF,0) );

		// Auto walk
		if( cd.has("autoWalk") ) {
			dx += dir * spd * tmod;
		}

		// Brake on cliff
		if( onGround && level.hasMark(CliffHigh, cx,cy, M.sign(dxTotal)) && cliffInsistF<=1*Const.FPS ) {
			trace("brake");
			var cliffXr = ( 0.5 + 0.4*M.sign(dxTotal) );
			var ratio = 1-M.fabs( cliffXr - xr );
			dx *= Math.pow(0.9 - ratio*0.8,tmod);
			// debug( M.pretty(ratio,1) );
		}


		// Jump
		if( onGround && ca.aPressed() ) {
			jump();

			// for( d in -1...2 ) {
			// 	// Climb small step
			// 	if( level.hasMark(StepSmall, cx+d, cy) && sightCheckCase(cx+d,cy) ) {
			// 		var stepDir = level.getMarkDir(StepSmall, cx+d, cy);
			// 		queueAutoAction( -M.fabs(d) + (M.sign(dir)==M.sign(stepDir) ? 2 : 0 ), ()->{
			// 			autoWalkS(stepDir, M.iabs(d)>0 ? 0.45 : 0.3);
			// 			xr = 0.5;
			// 			dy*=0.5;
			// 		});
			// 	}
			// 	// Climb high step
			// 	if( level.hasMark(StepHight, cx+d, cy) && sightCheckCase(cx+d,cy) ) {
			// 		var stepDir = level.getMarkDir(StepHight, cx+d, cy);
			// 		queueAutoAction( -M.fabs(d) + (M.sign(dir)==M.sign(stepDir) ? 2 : 0 ), ()->{
			// 			autoWalkS(stepDir, M.iabs(d)>0 ? 0.45 : 0.3);
			// 			xr = 0.5;
			// 		});
			// 	}
			// }

			// for(stepDir in [-2,-1,1,2]) {
			// 	// Climb small step
			// 	if( level.hasMark(StepSmall,cx,cy) ) {
			// 		var stepDir = level.getMarkDir(StepSmall,cx,cy);
			// 		queueAutoAction( -M.iabs(stepDir) + (M.sign(dir)==M.sign(stepDir) ? 5 : 0 ), ()->{
			// 			autoWalkS(stepDir, M.fabs(stepDir)>1 ? 0.45 : 0.3);
			// 			xr = 0.5;
			// 			dy*=0.5;
			// 		});
			// 	}
			// 	// if( level.hasCollision(cx+stepDir,cy) && !level.hasCollision(cx+stepDir,cy-1) )

			// 	// Climb high step
			// 	// if( level.hasCollision(cx+stepDir,cy) && level.hasCollision(cx+stepDir,cy-1) && !level.hasCollision(cx+stepDir,cy-2) )
			// 	// 	queueAutoAction( -M.iabs(stepDir) + (M.sign(dir)==M.sign(stepDir) ? 5 : 0 ), ()->{
			// 	// 		autoWalkS(stepDir, M.fabs(stepDir)>1 ? 0.45 : 0.3);
			// 	// 		xr = 0.5;
			// 	// 	});
			// }
		}
		else if( cd.has("extraJump") ) {
			dy += -0.07*tmod;
		}

		if( autoActions.length>0 ) {
			var dh = new dn.DecisionHelper(autoActions);
			dh.score( (a)->a.weight );
			dh.getBest().cb();
			autoActions = [];
		}
	}

}