from src.livraison_express_lite.infrastructure.implementation.dev.order_generator import (
    generate_labeled_orders,
)


def test_generation_reproductible_avec_la_meme_graine():
    orders_a, labels_a = generate_labeled_orders(n_rows=200, random_state=42)
    orders_b, labels_b = generate_labeled_orders(n_rows=200, random_state=42)

    assert orders_a == orders_b
    assert labels_a == labels_b


def test_une_etiquette_binaire_par_commande():
    orders, labels = generate_labeled_orders(n_rows=200)

    assert len(orders) == len(labels) == 200
    assert set(labels) <= {0, 1}
