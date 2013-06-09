package tink.markup.formats;

import haxe.macro.Expr;
//import haxe.macro.Format;

using tink.macro.tools.MacroTools;
using Lambda;

class Dom {
	var stack:List<String>;
	var target:Expr;
	public function new() {
		this.stack = new List();
	}
	function open() {
		var name = String.tempName();
		stack.push(name);
		target = name.resolve();
		return name;
	}
	function close() {
		var ret = stack.pop();
		var name = stack.first();
		target = 
			if (name == null) null;
			else 
				name.resolve();
		return ret.resolve();		
	}
	public function init(pos:Position):Null<Expr> {
		return open().define(macro js.Browser.document.createElement('tmp')).finalize(pos);
	}
	public function finalize(pos:Position):Null<Expr> {
		return close();
	}
	public function defaultTag(pos:Position):Expr {
		return 'div'.toExpr(pos);
	}
	static var SIMPLE = macro {
		var NAME__wrap = EXPR__wrapper;
		NAME__wrap.appendChild(EXPR__payload);
		NAME__wrap;
	}
	public function postprocess(e:Expr):Expr {
		return 
			switch e.match(SIMPLE) {
				case Success(m): 
					//m.exprs.toFields().log();
					m.exprs.payload;// .log();
				default:
					(macro $e.childNodes).finalize(e.pos);
			}
	}
	public function setProp(attr:String, value:Expr, pos:Position):Expr {
		return (macro $target.setAttribute($v{attr}, Std.string($value))).finalize(pos);
	}
	function addChildNode(e:Expr):Expr {
		return (macro $target.appendChild($e)).finalize(e.pos);
	}
	function doAddChild(target:Expr, e:Expr):Expr {
		return (
			if (e.is(macro: js.html.Node))
				macro $target.appendChild($e)
			else
				macro $target.appendChild(js.Browser.document.createTextNode(Std.string($e)))
		).finalize(e.pos);
	}
	public function addChild(e:Expr, ?t:Type):Expr {
		return doAddChild.bind(target, e).bounce();
	}
	public function addString(s:String, pos:Position):Expr {
		return (macro $target.appendChild(js.Browser.document.createTextNode($v{s}))).finalize(pos);
	}
	public function buildNode(nodeName:Expr, props:Array<Expr>, children:Array<Expr>, pos:Position, yield:Expr->Expr):Expr {
		var node = 
			switch nodeName.expr {
				case EConst(CString(name)) if (tags.exists(name)): tags.get(name);
				default: macro js.Browser.document.createElement($nodeName);
			}
		var ret = [open().define(node, pos)];
		for (p in props)
			ret.push(yield(p));
		for (c in children)
			ret.push(yield(c));
		ret.push(close());
		return addChildNode(ret.toBlock(pos));
	}
	static public function build(e:Expr) 
		return
			switch (e.expr) {
				case EMeta( { name : 'dom', params: [] }, e):
					TreeCrawler.build(e, new Tags(new Dom()));
				default: e;
			}
			
	static var tags = [
		"td" => macro js.Browser.document.createTableCellElement(),	
		"hr" => macro js.Browser.document.createHRElement(),			
		"marquee" => macro js.Browser.document.createMarqueeElement(),		
		"basefont" => macro js.Browser.document.createBaseFontElement(),	
		"select" => macro js.Browser.document.createSelectElement(),		
		"map" => macro js.Browser.document.createMapElement(),			
		"form" => macro js.Browser.document.createFormElement(),		
		"option" => macro js.Browser.document.createOptionElement(),		
		"label" => macro js.Browser.document.createLabelElement(),		
		"meta" => macro js.Browser.document.createMetaElement(),		
		"img" => macro js.Browser.document.createImageElement(),		
		"dl" => macro js.Browser.document.createDListElement(),		
		"frame" => macro js.Browser.document.createFrameElement(),		
		"mod" => macro js.Browser.document.createModElement(),			
		"ul" => macro js.Browser.document.createUListElement(),		
		"output" => macro js.Browser.document.createOutputElement(),		
		"ol" => macro js.Browser.document.createOListElement(),		
		"shadow" => macro js.Browser.document.createShadowElement(),		
		"li" => macro js.Browser.document.createLIElement(),			
		"datalist" => macro js.Browser.document.createDataListElement(),	
		"param" => macro js.Browser.document.createParamElement(),		
		"font" => macro js.Browser.document.createFontElement(),		
		"track" => macro js.Browser.document.createTrackElement(),		
		"applet" => macro js.Browser.document.createAppletElement(),		
		"area" => macro js.Browser.document.createAreaElement(),		
		"link" => macro js.Browser.document.createLinkElement(),		
		"div" => macro js.Browser.document.createDivElement(),			
		"title" => macro js.Browser.document.createTitleElement(),		
		"style" => macro js.Browser.document.createStyleElement(),		
		"progress" => macro js.Browser.document.createProgressElement(),	
		"button" => macro js.Browser.document.createButtonElement(),		
		"fieldset" => macro js.Browser.document.createFieldSetElement(),	
		"a" => macro js.Browser.document.createAnchorElement(),		
		"iframe" => macro js.Browser.document.createIFrameElement(),		
		"span" => macro js.Browser.document.createSpanElement(),		
		"details" => macro js.Browser.document.createDetailsElement(),		
		"body" => macro js.Browser.document.createBodyElement(),		
		"input" => macro js.Browser.document.createInputElement(),		
		"embed" => macro js.Browser.document.createEmbedElement(),		
		"meter" => macro js.Browser.document.createMeterElement(),		
		"pre" => macro js.Browser.document.createPreElement(),			
		"thead" => macro js.Browser.document.createTableSectionElement(),
		"head" => macro js.Browser.document.createHeadElement(),		
		"base" => macro js.Browser.document.createBaseElement(),		
		"optgroup" => macro js.Browser.document.createOptGroupElement(),	
		"quote" => macro js.Browser.document.createQuoteElement(),		
		"audio" => macro js.Browser.document.createAudioElement(),		
		"video" => macro js.Browser.document.createVideoElement(),		
		"legend" => macro js.Browser.document.createLegendElement(),		
		"menu" => macro js.Browser.document.createMenuElement(),		
		"frameset" => macro js.Browser.document.createFrameSetElement(),	
		"canvas" => macro js.Browser.document.createCanvasElement(),		
		"keygen" => macro js.Browser.document.createKeygenElement(),		
		"col" => macro js.Browser.document.createTableColElement(),	
		"dir" => macro js.Browser.document.createDirectoryElement(),	
		"table" => macro js.Browser.document.createTableElement(),		
		"tr" => macro js.Browser.document.createTableRowElement(),	
		"script" => macro js.Browser.document.createScriptElement(),		
		"source" => macro js.Browser.document.createSourceElement(),		
		"p" => macro js.Browser.document.createParagraphElement(),	
		"content" => macro js.Browser.document.createContentElement(),		
		"br" => macro js.Browser.document.createBRElement(),			
		"html" => macro js.Browser.document.createHtmlElement(),		
		"textarea" => macro js.Browser.document.createTextAreaElement(),	
		"media" => macro js.Browser.document.createMediaElement(),		
		"object" => macro js.Browser.document.createObjectElement(),		
		"caption" => macro js.Browser.document.createTableCaptionElement(),
	];	
}