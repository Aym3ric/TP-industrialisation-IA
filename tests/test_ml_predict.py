from src.livraison_express_lite.core.learning.ml_predict import MLPredict
from src.livraison_express_lite.core.learning.order_feature import FEATURE_COLUMNS

from .conftest import FakeModel


def test_probabilite_au_dessus_du_seuil_donne_oui(order):
    prediction = MLPredict(FakeModel(0.8), threshold=0.5).predict(order)

    assert prediction.express_eligible is True
    assert prediction.decision == "oui"
    assert prediction.probability == 0.8


def test_probabilite_sous_le_seuil_donne_non(order):
    prediction = MLPredict(FakeModel(0.3), threshold=0.5).predict(order)

    assert prediction.express_eligible is False
    assert prediction.decision == "non"


def test_le_seuil_est_inclusif(order):
    prediction = MLPredict(FakeModel(0.5), threshold=0.5).predict(order)

    assert prediction.decision == "oui"


def test_le_modele_recoit_les_colonnes_du_contrat(order):
    model = FakeModel(0.7)
    MLPredict(model, threshold=0.5).predict(order)

    assert list(model.received.columns) == FEATURE_COLUMNS
