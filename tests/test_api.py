from dataclasses import asdict

import pytest
from fastapi.testclient import TestClient

from src.livraison_express_lite.api.app import create_app
from src.livraison_express_lite.core.learning.ml_predict import MLPredict

from .conftest import FakeModel


@pytest.fixture
def app():
    return create_app()


def test_health_repond_toujours(app):
    response = TestClient(app).get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_sans_modele_ready_et_predict_renvoient_503(app, order):
    app.state.predict_service = None
    client = TestClient(app)

    assert client.get("/health/ready").status_code == 503
    assert client.post("/predict", json=asdict(order)).status_code == 503


def test_predict_avec_modele(app, order):
    app.state.predict_service = MLPredict(FakeModel(0.9), threshold=0.5)
    client = TestClient(app)

    assert client.get("/health/ready").status_code == 200
    response = client.post("/predict", json=asdict(order))

    assert response.status_code == 200
    body = response.json()
    assert body["decision"] == "oui"
    assert body["probability"] == 0.9


def test_payload_invalide_renvoie_422(app):
    app.state.predict_service = MLPredict(FakeModel(0.9), threshold=0.5)

    response = TestClient(app).post("/predict", json={"hour": "pas un entier"})

    assert response.status_code == 422
