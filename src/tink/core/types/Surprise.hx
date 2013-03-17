package tink.core.types;

typedef Surprise<D, F> = Future<Outcome<D, F>>;

abstract LeftFailingHandler<D, F>(F->D->Void) {
	public function new(f) this = f;
}
abstract RightFailingHandler<D, F>(D->F->Void) {
	public function new(f) this = f;	
}