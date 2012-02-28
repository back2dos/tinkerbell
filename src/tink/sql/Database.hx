package tink.sql;

import sys.db.Connection;

/**
 * ...
 * @author back2dos
 */

@:autoBuild(tink.sql.macros.DBBuild.build()) class Database {
	public var cnx(default, null):Connection;
	function new(cnx) {
		this.cnx = cnx;
	}
	public function insert(table:String, fields:Array<String>, values:Array<Dynamic>) {
		var s = new StringBuf();
		s.add(Std.format('INSERT INTO ${table} (${fields.join(", ")}) VALUES ('));
		var first = true;
		for (v in values) {
			if (first) 
				first = false;
			else 
				s.add(', ');
			cnx.addValue(s, v);
		}
		s.add(')');
		cnx.request(s.toString());
	}
}