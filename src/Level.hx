class Level extends dn.Process {
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;

	public var wid(get,never) : Int; inline function get_wid() return data.l_Collisions.cWid;
	public var hei(get,never) : Int; inline function get_hei() return data.l_Collisions.cHei;

	public var idx : Int;
	public var data : World.World_Level;
	var tilesetSource : h2d.Tile;

	var marks : Map< LevelMark, Map<Int,Int> > = new Map();
	var invalidated = true;

	public function new(idx:Int, lvl:World.World_Level) {
		super(Game.ME);
		this.idx = idx;
		createRootInLayers(Game.ME.scroller, Const.DP_BG);
		data = lvl;
		tilesetSource = hxd.Res.world.tiles.toTile();

		for(cy in 0...hei)
		for(cx in 0...wid) {
			if( !hasCollision(cx,cy) && hasCollision(cx,cy+1) ) {
				for( dir in [-1,1] ) {
					if( hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy-1) )
						setMark(StepSmall, cx,cy, dir);
					else if( hasCollision(cx+dir,cy) && hasCollision(cx+dir,cy-1) && !hasCollision(cx+dir,cy-2) )
						setMark(StepHight, cx,cy, dir);

					if( !hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy+2) )
						setMark(CliffHigh, cx,cy, dir);
					else if( !hasCollision(cx+dir,cy) && !hasCollision(cx+dir,cy+1) )
						setMark(CliffSmall, cx,cy, dir);
				}
			}
		}
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
		return !isValid(cx,cy) ? true : data.l_Collisions.getInt(cx,cy)==0;
	}

	/** Render current level**/
	function render() {
		root.removeChildren();

		var tg = new h2d.TileGroup(tilesetSource, root);
		data.l_Collisions.renderInTileGroup(tg, false);
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}
}