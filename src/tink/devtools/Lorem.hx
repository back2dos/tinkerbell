package tink.devtools;


class Lorem {
	static public var randFloat = Math.random;
	static public function html(?paragraphs = 3, ?sentences = 5, ?words = 10) {
		return '<p>' + ipsum('</p><p>', paragraphs, sentences, words) + '</p>';
	}
	static public function ipsum(?sep = '\n', ?paragraphs = 3, ?sentences = 5, ?words = 10) {
		return text.text(sep, paragraphs, sentences, words);
	}
	static public var person = new RandomPerson();
	static public var text = new RandomText(
		.3,
		'.',
		" | | | | | | | |, |, | - ".split('|'),
		"lorem ipsum dolor sit amet consetetur sadipscing elitr sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat sed diam voluptua at vero eos et accusam et justo duo dolores et ea rebum stet clita kasd gubergren no sea takimata sanctus est lorem ipsum dolor sit amet lorem ipsum dolor sit amet consetetur sadipscing elitr sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat sed diam voluptua at vero eos et accusam et justo duo dolores et ea rebum stet clita kasd gubergren no sea takimata sanctus est lorem ipsum dolor sit amet".split(' ')
	);
}
private class Randomness {
	
	function randInt(x:Int) return Std.int(randFloat() * x);
	function randFloat():Float return Lorem.randFloat();
	
	function rnd(from:Array<String>) {
		return from[randInt(from.length)];
	}
	function randomize(value) {
		value = Std.int(value * (.5 + randFloat()));
		if (value < 1) value = 1;
		return value;
	}
	function ucFirst(s:String) {
		return s.charAt(0).toUpperCase() + s.substr(1);
	}	
}
enum Casing {
	Normal;
	AllCaps;
}
enum Sex {
	Male;
	Female;
	Any;
}
class RandomPerson extends Randomness {
	var firstNamesM:Array<String>;
	var firstNamesF:Array<String>;
	var lastNames:Array<String>;
	public function new() {
		this.firstNamesM = 'Oliver,Jack,Ethan,Jacob,Thomas,Alfie,Dylan,Charlie,Joshua,Logan'.split(',');
		this.firstNamesF = 'Ruby,Olivia,Lily,Amelia,Seren,Ava,Chloe,Megan,Sophie,Mia'.split(',');
		this.lastNames = 'Smith,Jones,Taylor,Brown,Williams,Wilson,Johnson,Davis,Robinson,Wright,Thompson,Evans,Walker,White,Roberts,Green,Hall,Wood,Jackson,Clarke'.split(',');
	}
	public function first(?sep = '', ?sex:Sex) {
		if (sex == null) sex = Any;
		var from = 
			switch (sex) {
				case Male: firstNamesM;
				case Female: firstNamesF;
				case Any: 
					if (randFloat() < .5) firstNamesF;
					else firstNamesM;
			}
			
		var ret = rnd(from);
		for (i in 0...sep.length)
			ret += sep.charAt(i) + rnd(from);
		return ret;
	}
	function nothing(s:String) {
		return s;
	}
	function upper(s:String) {
		return s.toUpperCase();
	}
	public function last(?sep = '', ?t) {
		if (t == null) t = Normal;
		var t =
			switch (t) {
				case Normal: nothing;
				case AllCaps: upper;
			}
		var ret = t(rnd(lastNames));
		for (i in 0...sep.length)
			ret += sep.charAt(i) + t(rnd(lastNames));
		return ret;		
	}
	public function getEmail() {
		return first().toLowerCase() + '.' + last().toLowerCase() + '@example.com';
	}
}
class RandomText extends Randomness {
	var ucFrequency:Float;
	var terminator:String;
	var separators:Array<String>;
	var words:Array<String>;
	public function new(ucFrequency, terminator, separators, words) {
		this.ucFrequency = ucFrequency;
		this.terminator = terminator;
		this.separators = separators;
		this.words = words;
	}
	
	public function word(?ucFrequency) {
		var ret = rnd(words);
		if (Math.isNaN(ucFrequency)) ucFrequency = this.ucFrequency;
		if (randFloat() < ucFrequency) ret = ucFirst(ret);
		return ret;
	}
	
	public function sentence(?words = 10) {
		var ret = word(1);
		for (i in 0...randomize(words - 1))
			ret += rnd(separators) + word(ucFrequency);
		return ret + terminator;			
	}
	public function paragraph(?sentences = 5, ?words = 10) {
		sentences = randomize(sentences);
		var ret = [];
		for (i in 0...randomize(sentences))
			ret.push(sentence(words));
		return ret.join(' ');
	}
	public function text(?sep = '\n', ?paragraphs = 3, ?sentences = 5, ?words = 10) {
		var ret = [];
		for (i in 0...randomize(paragraphs)) 
			ret.push(paragraph(sentences, words));
		return ret.join(sep);
	}	
}