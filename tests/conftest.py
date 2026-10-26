"""Doublures partagées par les tests.

On ne teste pas une orchestration avec un vrai modèle : un faux modèle renvoie une
probabilité connue, sans entraînement coûteux.
"""

import numpy as np
import pytest

from src.livraison_express_lite.domain.entities import OrderEntity


class FakeModel:
    """Imite `Pipeline.predict_proba` avec une probabilité fixe pour la classe 1."""

    def __init__(self, probability: float):
        self.probability = probability
        self.received = None

    def predict_proba(self, input_df):
        self.received = input_df
        return np.array([[1 - self.probability, self.probability]])


@pytest.fixture
def order() -> OrderEntity:
    return OrderEntity(
        hour=14,
        day_of_week=2,
        weekend=0,
        distance_km=3.5,
        order_value_eur=89.9,
        weight_kg=2.4,
        stock_available=1,
        preparation_time_min=18,
        carrier_capacity=0.85,
        weather="normal",
        delivery_zone="centre",
        customer_type="premium",
        order_id="CMD-000001",
    )
