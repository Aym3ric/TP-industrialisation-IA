from src.livraison_express_lite.core.learning.order_feature import (
    CATEGORICAL_FEATURES,
    FEATURE_COLUMNS,
    NUMERIC_FEATURES,
    orders_to_dataframe,
)


def test_dataframe_respecte_l_ordre_des_features(order):
    df = orders_to_dataframe([order])

    assert list(df.columns) == FEATURE_COLUMNS
    assert len(df) == 1


def test_order_id_n_est_pas_une_feature(order):
    df = orders_to_dataframe([order])

    assert "order_id" not in df.columns


def test_features_numeriques_et_categorielles_couvrent_le_contrat():
    assert sorted(NUMERIC_FEATURES + CATEGORICAL_FEATURES) == sorted(FEATURE_COLUMNS)
    assert not set(NUMERIC_FEATURES) & set(CATEGORICAL_FEATURES)
