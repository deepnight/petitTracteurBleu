class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return data.l_Collisions.cWid;
	public var hei(get,never) : Int; inline function get_hei() return data.l_Collisions.cHei;

	public var idx : Int;
	public var data : World.World_Level;

	var marks : Map< LevelMark, Map<Int,Int> > = new Map();
	var invalidated = true;
	var parallax : h2d.TileGroup;

	var skyWrapper : h2d.Object;
	var skyDayFront : HSprite;
	var skyDayBack : HSprite;
	var skyNightFront : HSprite;
	var skyNightBack : HSprite;
	var sun : HSprite;
	var moon : HSprite;
	public var nightRatio = 0.;

	public function new(idx:Int, lvl:World.World_Level) {
		super(Game.ME);
		this.idx = idx;
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = lvl;

		skyWrapper = new h2d.Object();
		Game.ME.root.add(skyWrapper, Const.DP_BG);

		skyDayBack = Assets.tiles.h_get("bgDayBack", 0, 0,0.5, skyWrapper);
		skyNightBack = Assets.tiles.h_get("bgNightBack", 0, 0,0.5, skyWrapper);
		sun = Assets.tiles.h_get("sun",0, 0.5,0.5, skyWrapper);
		sun.blendMode = Add;
		moon = Assets.tiles.h_get("moon",0, 0.5,0.5, skyWrapper);
		moon.blendMode = Add;
		skyDayFront = Assets.tiles.h_get("bgDayFront", 0, 0,0.5, skyWrapper);

		skyNightFront = Assets.tiles.h_get("bgNightFront", 0, 0,0.5, skyWrapper);

		parallax = new h2d.TileGroup( Assets.ledTilesets.get(data.l_Parallax.tileset.identifier) );
		Game.ME.root.add(parallax, Const.DP_BG);
		parallax.colorMatrix = C.getColorizeMatrixH2d(Const.PARALLAX_NIGHT_COLOR, 0.9);
		parallax.filter = new h2d.filter.Blur(2, 1, 2);
		// parallax.alpha = 0.7;

		for(cy in 0...hei)
		for(cx in 0...wid) {
			if( !hasCollision(cx,cy) && hasCollision(cx,cy+1) ) {
				for( dir in [-1,1] ) {
					if( hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy-1) )
						setMark(StepSmall, cx,cy, dir);
					else if( hasCollision(cx+dir,cy) && hasCollision(cx+dir,cy-1) && !hasCollision(cx+dir,cy-2) )
						setMark(StepHight, cx,cy, dir);

					if( !hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy+3) && !hasCollision(cx+dir,cy+1) )
						setMark(CliffHigh, cx,cy, dir);
					else if( !hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy+1) )
						setMark(CliffSmall, cx,cy, dir);
				}
			}

			if( !hasCollision(cx,cy) )
				for( dir in [-1,1] ) {
					if( hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy-1) )
						setMark(EdgeGrab, cx,cy, dir);
				}
		}
	}

	override function onDispose() {
		super.onDispose();
		skyWrapper.remove();
		parallax.remove();
	}

	override function onResize() {
		super.onResize();
		skyWrapper.y = h()*0.5;
		skyWrapper.setScale( M.fclamp( M.fmax( w()/skyDayFront.tile.width, h()/skyDayFront.tile.height ), 1, 99 ) );
		parallax.setScale(Const.SCALE);
	}

	/**
		Mark the level for re-render at the end of current frame (before display)
	**/
	public inline function invalidate() {
		invalidated = true;
	}

	/**
		Return TRUE if given coordinates are in level bounds
	**/
	public inline function isValid(cx,cy) return cx>=0 && cx<wid && cy>=0 && cy<hei;

	/**
		Transform coordinates into a coordId
	**/
	public inline function coordId(cx,cy) return cx + cy*wid;


	/** Return TRUE if mark is present at coordinates **/
	public inline function hasMark(mark:LevelMark, cx:Int, cy:Int, ?dir:Null<Int>) {
		return !isValid(cx,cy) || !marks.exists(mark)
			? false
			: dir==null
				? marks.get(mark).exists( coordId(cx,cy) )
				: marks.get(mark).get( coordId(cx,cy) ) == ( dir==0 ? 0 : dir>0 ? 1 : -1 ) ;
	}

	public inline function getMarkDir(mark:LevelMark, cx:Int, cy:Int) : Int {
		return hasMark(mark,cx,cy) ? marks.get(mark).get( coordId(cx,cy) ) : 0;
	}

	/** Enable mark at coordinates **/
	public function setMark(mark:LevelMark, cx:Int, cy:Int, dir=0) {
		if( isValid(cx,cy) && !hasMark(mark,cx,cy) ) {
			if( !marks.exists(mark) )
				marks.set(mark, new Map());
			marks.get(mark).set( coordId(cx,cy), dir==0 ? 0 : dir>0 ? 1 : -1 );
		}
	}

	/** Remove mark at coordinates **/
	public function removeMark(mark:LevelMark, cx:Int, cy:Int) {
		if( isValid(cx,cy) && hasMark(mark,cx,cy) )
			marks.get(mark).remove( coordId(cx,cy) );
	}

	/** Return TRUE if "Collisions" layer contains a collision value **/
	public inline function hasCollision(cx,cy) : Bool {
		return !isValid(cx,cy)
			? true
			: data.l_Collisions.getInt(cx,cy)==0 || data.l_Collisions.getInt(cx,cy)==2 || data.l_Collisions.getInt(cx,cy)==4;
	}

	public function getGroundDist(cx,cy) {
		if( hasCollision(cx,cy) )
			return 0;

		var d = 0;
		while( !hasCollision(cx,cy+d+1) )
			d++;
		return d;
	}

	/** Render current level**/
	function render() {
		root.removeChildren();

		var atlasTile = Assets.ledTilesets.get( data.l_Collisions.tileset.identifier );

		var bg = new h2d.TileGroup(atlasTile, root);
		data.l_BgElements.renderInTileGroup(bg, false);
		bg.colorMatrix = C.getColorizeMatrixH2d(Const.BG_COLOR, 0.8);

		var shadow = new h2d.TileGroup(atlasTile, root);
		data.l_Shadows.renderInTileGroup(shadow, false);
		shadow.alpha = data.l_Shadows.opacity;

		var walls = new h2d.TileGroup(atlasTile, root);
		data.l_Collisions.renderInTileGroup(walls, false);

		var tilesMain = new h2d.TileGroup(atlasTile, root);
		data.l_TilesMain.renderInTileGroup(tilesMain, false);

		var tilesFront = new h2d.TileGroup(atlasTile, root);
		data.l_TilesFront.renderInTileGroup(tilesFront, false);

		// data.l_Parallax.renderInTileGroup(parallax, true);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}

		parallax.x = game.scroller.x*0.7;
		parallax.y = game.scroller.y*0.75;

		sun.x = w()*0.2 / skyWrapper.scaleX;
		sun.y = ( -0.4 + nightRatio*1 ) * h()  / skyWrapper.scaleY;

		moon.x = w()*0.9 / skyWrapper.scaleX;
		moon.y = ( 0.5 - nightRatio*0.8 ) * h()  / skyWrapper.scaleY;

		skyNightBack.alpha = nightRatio;
		skyNightFront.alpha = nightRatio;
		var c = C.interpolateInt(Const.PARALLAX_DAY_COLOR,Const.PARALLAX_NIGHT_COLOR,nightRatio);
		var m = C.getColorizeMatrixH2d(c, 0.9);
		parallax.colorMatrix.load(m);

		var m = C.getColorizeMatrixH2d(c, nightRatio*0.4);
		game.teint.matrix.load(m);
	}
}