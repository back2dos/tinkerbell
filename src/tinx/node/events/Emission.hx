package tinx.node.events;

import tink.reactive.signals.Signal;

class Emission<T> extends EmissionBase<T->Void> implements Signal<T> {
}